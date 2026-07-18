# API Mapping — Mobile screen ↔ Backend

Base URL be-blog: `AppConfig.apiBaseUrl`  
Base URL messaging: `AppConfig.messagingBaseUrl`

Auth: `Authorization: Bearer <JWT>` (trừ endpoint public).

## Auth

| Màn hình | Method | Endpoint |
|---|---|---|
| Login | POST | `/api/auth/login` |
| Guest | POST | `/api/auth/guest` |
| Register | POST | `/api/auth/register` |
| Verify email | POST | `/api/auth/verify-email` |
| Resend verification | POST | `/api/auth/resend-verification` |
| Forgot password | POST | `/api/auth/forgot-password` |
| Reset password | POST | `/api/auth/reset-password` |
| Startup / me | GET | `/api/users/me` |
| Logout (local) | — | Xóa token + `DELETE /api/notifications/devices` |

## Home / Feed

| UI | Method | Endpoint |
|---|---|---|
| Home timeline | GET | `/api/feed?page=&size=` |
| User feed | GET | `/api/feed/users/{userId}` |
| Trending | GET | `/api/feed/trending` |
| Streak box | GET | `/api/streak/me` |
| Newsletter | POST | `/api/public/newsletter/subscribe` |

## Posts

| UI | Method | Endpoint |
|---|---|---|
| List / network | GET | `/api/posts?scope=&page=&size=` |
| My posts | GET | `/api/users/me/posts` |
| Detail | GET | `/api/posts/{id}` |
| Create | POST multipart | `/api/posts` (`title`, `content`, `titleImage`, `images`) |
| Update | PUT multipart | `/api/posts/{id}` |
| Append gallery | POST multipart | `/api/posts/{id}/gallery` |
| Delete gallery image | DELETE | `/api/posts/{id}/gallery/{imageId}` |
| Delete post | DELETE | `/api/posts/{id}` |
| Admin pending | GET | `/api/admin/posts/pending` |
| Approve / Reject | POST | `/api/admin/posts/{id}/approve\|reject` |

## Reviews / Books / Reading list

| UI | Method | Endpoint |
|---|---|---|
| Reviews list | GET | `/api/reviews` |
| Review detail | GET | `/api/reviews/{id}` |
| Create/update review | POST/PUT | `/api/reviews` |
| Books | GET/POST/PUT/DELETE | `/api/books`, `/api/books/{id}` |
| My books | GET | `/api/books/me` |
| Reading list | GET/POST/PATCH/DELETE | `/api/reading-list/me` |

## Social

| UI | Method | Endpoint |
|---|---|---|
| Likes status (review) | GET | `/api/reviews/{id}/likes/count` |
| Like / unlike review | POST/DELETE | `/api/reviews/{id}/likes` |
| Likes status (post) | GET | `/api/posts/{id}/likes/count` |
| Like / unlike post | POST/DELETE | `/api/posts/{id}/likes` |
| Comments | GET/POST/PUT/DELETE | `/api/reviews/{id}/comments…` |
| Bookmarks me | GET | `/api/bookmarks/me` |
| Bookmark status / toggle | GET/POST/DELETE | `/api/bookmarks…` |

## Search / Users / Friends

| UI | Method | Endpoint |
|---|---|---|
| Archive search | GET | `/api/search?q=&type=&page=&size=` |
| User search | GET | `/api/users/search?q=` |
| Profile | GET | `/api/users/{id}/profile` |
| User posts/books/reviews | GET | `/api/users/{id}/posts\|books\|reviews` |
| Friends | GET/POST/… | `/api/friends…` |

## Notifications

| UI | Method | Endpoint |
|---|---|---|
| List | GET | `/api/notifications` |
| Unread badge | GET | `/api/notifications/unread-count` |
| Mark read | PATCH | `/api/notifications/{id}/read` |
| Mark all | POST | `/api/notifications/read-all` |
| FCM device | POST/DELETE | `/api/notifications/devices` |
| Tùy chọn push theo loại (Settings) | GET/PUT | `/api/notifications/preferences` |
| SSE (web) | GET | `/api/notifications/stream` — mobile dùng polling |

## Messaging-service

| UI | Method | Endpoint |
|---|---|---|
| WS ticket | POST | `/api/chat/ws-ticket` |
| Conversations | GET | `/api/chat/conversations` |
| Unread | GET | `/api/chat/unread-count` |
| Friends for chat | GET | `/api/chat/friends` |
| Create direct/group | POST | `/api/chat/conversations/direct\|group` |
| Messages (cursor) | GET | `/api/chat/conversations/{id}/messages?before=&size=` |
| Send | POST | `/api/chat/conversations/{id}/messages` |
| Read / edit / revoke / react | POST/PATCH/DELETE/PUT | `/api/chat/…` |
| Attachment presign | POST | `/api/chat/conversations/{id}/attachments/presign` |
| Attachment complete | POST | `/api/chat/attachments/{id}/complete` |
| Attachment download | GET | `/api/chat/attachments/{id}/download` |
| Local storage upload/download | PUT/GET | `/api/chat/local-storage` (khi S3 tắt) |
| Call config (ICE/TURN) | GET | `/api/chat/config` |
| Tạo / nhận / từ chối / kết thúc gọi | POST | `/api/chat/conversations/{id}/calls`, `/api/chat/calls/{id}/answer\|reject\|end` |
| Call signal durable | POST/GET | `/api/chat/call-signals` |
| Realtime | WS | `{wsBase}/ws?ticket=` (`call.offer|answer|ice|ringing|end…`) |

## Notes / Calendar / Catalog / Admin

| UI | Method | Endpoint |
|---|---|---|
| Notes | CRUD | `/api/notes/me…` |
| Calendar | CRUD | `/api/calendar/me…` |
| Tags / genres / authors | CRUD | `/api/tags`, `/api/genres`, `/api/authors` |
| Admin users | GET/PATCH | `/api/users…` (admin) |
| Change password | PUT | `/api/users/me/password` |

## Phân trang

- be-blog: Spring `page` / `size`, body `content[]`
- messaging: cursor `before` / `nextCursor`
