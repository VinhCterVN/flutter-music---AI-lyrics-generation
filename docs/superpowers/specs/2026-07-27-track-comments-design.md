# Track Comments — Design

Date: 2026-07-27
Status: Approved

## Overview

Add a comments feature to the music app: users can comment on tracks (multiple comments per user per track), reply to comments (single-level, YouTube-style), like comments, edit/delete their own comments, and see new comments in realtime. Backend is a single Supabase SQL file (run manually in the Supabase SQL editor); frontend is a comments bottom sheet opened from the playing screen.

## Decisions

- **Reply depth**: single-level. Replies attach to a top-level comment; replying to a reply re-points to the top-level parent (enforced server-side by trigger).
- **Delete**: soft delete. Deleted comments keep a `[deleted]` placeholder so replies remain visible. UPDATE-only RLS; no hard DELETE policy. Top-level queries filter out deleted comments that have no replies.
- **Extras**: comment likes, edit (with "edited" flag), realtime updates.
- **Architecture**: plain table queries + PostgREST embeds + Supabase realtime stream (approach A). No RPCs, no counter triggers — counts come from embedded `count` aggregates.

## 1. SQL schema — `supabase/comments.sql`

Single idempotent file (`create table if not exists`, `drop policy if exists` before `create policy`, `create or replace function`).

### `comments`

| column     | type        | notes |
|------------|-------------|-------|
| id         | uuid PK     | `gen_random_uuid()` |
| track_id   | int8        | NOT NULL, FK `tracks(id)` ON DELETE CASCADE |
| user_id    | uuid        | NOT NULL, FK `users(id)` ON DELETE CASCADE |
| parent_id  | uuid NULL   | FK `comments(id)` ON DELETE CASCADE; NULL = top-level |
| content    | text        | NOT NULL, `check (char_length(content) between 1 and 2000)` |
| is_deleted | bool        | default false; soft delete blanks content |
| is_edited  | bool        | default false; set by trigger when content changes |
| created_at | timestamptz | default now() |
| updated_at | timestamptz | default now(), maintained by trigger |

### `comment_likes`

| column     | type        | notes |
|------------|-------------|-------|
| comment_id | uuid        | FK `comments(id)` ON DELETE CASCADE |
| user_id    | uuid        | FK `users(id)` ON DELETE CASCADE |
| created_at | timestamptz | default now() |

PK `(comment_id, user_id)` — one like per user per comment.

### Triggers

1. **`flatten_comment_parent`** (BEFORE INSERT): if `parent_id` points at a comment that itself has a `parent_id`, re-point to that comment's top-level parent. Enforces single-level threading.
2. **`comment_before_update`** (BEFORE UPDATE): if `content` changed and not a soft-delete, set `is_edited = true`; always bump `updated_at`.

### Indexes

- `comments(track_id, created_at desc) where parent_id is null` — top-level listing
- `comments(parent_id)` — reply lookup
- `comment_likes(comment_id)` — like counts

### RLS

- `comments`: SELECT for authenticated; INSERT with `user_id = auth.uid()`; UPDATE own rows (`using` + `with check` on `auth.uid() = user_id`). No DELETE policy.
- `comment_likes`: SELECT authenticated; INSERT own (`user_id = auth.uid()`); DELETE own.
- Realtime: `alter publication supabase_realtime add table comments`.

## 2. Flutter — data layer

### Model — `lib/data/models/comment.dart`

`Comment`: `id, trackId, userId, userName, userPhotoUrl, parentId, content, isDeleted, isEdited, likeCount, likedByMe, replyCount, createdAt`. `fromJson` maps embeds: `users(display_name, photo_url)`, `comment_likes(count)`, own-like sub-select, `replies:comments(count)`. `copyWith` for optimistic like updates.

### Service — `lib/service/comment_service.dart`

`CommentService(Ref ref)` with `_supabase = ref.read(supabaseClientProvider)` (same pattern as `TrackService`):

- `getComments(int trackId)` — top-level (`parent_id is null`), newest first, filters out deleted comments with zero replies, embeds user/likes/reply-count/liked-by-me
- `getReplies(String parentId)` — oldest first, same embeds (no reply count)
- `addComment(int trackId, String content, {String? parentId})`
- `editComment(String id, String content)`
- `deleteComment(String id)` — update `is_deleted = true, content = ''`
- `setLike(String commentId, bool liked)` — insert/delete `comment_likes`
- `commentsStream(int trackId)` — `.stream(primaryKey: ['id']).eq('track_id', trackId)`; used only as an invalidation signal

### Providers — `lib/provider/comment_provider.dart`

- `commentServiceProvider = Provider<CommentService>`
- `trackCommentsProvider(int trackId)` — async family fetching top-level comments; listens to `commentsStream` and refetches on change
- `commentRepliesProvider(String parentId)` — async family for replies

## 3. Flutter — UI

### `lib/ui/component/navigation/comments_bottom_sheet.dart`

`showCommentsBottomSheet(BuildContext, {required Track track})` → `showModalBottomSheet(useRootNavigator: true, isScrollControlled: true, backgroundColor: transparent)` wrapping a `DraggableScrollableSheet` (initial ~0.7, max 0.95).

Style matches existing sheets: drag handle (40×4), `scheme.surfaceDim` background, `BorderRadius.vertical(top: 24)`.

Layout:
- **Header**: "Comments" title + total count.
- **List** (scrollable): each comment shows avatar, display name, relative timestamp, "(edited)" suffix, content, heart icon + like count (optimistic toggle with rollback on error), "Reply" action. `[deleted]` placeholder for soft-deleted parents. "View N replies" expander loads `commentRepliesProvider` and renders replies indented one level.
- **Own-comment menu**: overflow/long-press → Edit (inline via input bar) / Delete (confirm dialog).
- **Input bar** pinned at bottom: current-user avatar, text field, send button (disabled while empty/posting); keyboard-aware via `MediaQuery.viewInsets`. Reply mode shows "Replying to <name> ✕" strip; edit mode pre-fills text and shows "Editing ✕" strip.
- **States**: loading spinner, error + retry, empty state ("Be the first to comment").

### Entry point — `playing_screen.dart`

Comment icon button (`Icons.comment_outlined` or similar) in the existing action row of the playing screen; opens the sheet with the track from `currentTrackProvider`. Disabled when no track.

## 4. Error handling

- Async providers surface error + retry in the sheet.
- Optimistic like toggles roll back on failure.
- Send button disabled during in-flight post; failures show a SnackBar and keep the drafted text.

## 5. Testing

- SQL is run manually by the user in Supabase SQL editor; the file is idempotent so it can be re-run safely.
- Flutter side verified manually in the running app: post, reply, like, edit, delete, realtime update from a second client.
