# HoYoLAB API reference (HoYo AIO)

This document is the **only** source the Dart API layer is built from (see `CLAUDE.md` §6).
Every value here lands in exactly one Dart file: `lib/core/hoyolab/hoyolab_config.dart`.

- **Researched from:** [danggai/android_genshin_resin_widget](https://github.com/danggai/android_genshin_resin_widget)
  (MIT), commit [`9b04b0e`](https://github.com/danggai/android_genshin_resin_widget/tree/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c)
  (2026-11-06). Only API knowledge was taken; no code was copied.
- **Scope:** global (overseas) servers only (D7). China endpoints and salts in the reference
  repo are listed once for completeness and are **not** used.
- **Status markers:**
  - ✅ Confirmed in the reference repo source (still needs a live request in the phase that uses it).
  - ⚠️ VERIFY: not in the reference repo, inferred, outdated-looking, or behavior unclear.
    Each one has a reason. Nothing marked ⚠️ is built without a live check first.
- **Samples:** all JSON samples are **reconstructed from the reference repo's DTOs and
  comments**, not captured live. UIDs, nicknames and cookies are fake.

All source links point at commit `9b04b0e` so line numbers stay valid.

---

## 1. Hosts

| Purpose | Host | Status | Source |
|---|---|---|---|
| Game record (GI/HSR notes, record card, data switch) | `https://bbs-api-os.hoyoverse.com` | ✅ | [`Constant.kt#L14`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/util/Constant.kt#L14), [`NetworkModule.kt#L57`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/module/NetworkModule.kt#L57) |
| ZZZ notes | `https://sg-act-nap-api.hoyolab.com` | ✅ | [`Constant.kt#L17`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/util/Constant.kt#L17) |
| GI check-in | `https://sg-hk4e-api.hoyolab.com` | ✅ | [`Constant.kt#L22`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/util/Constant.kt#L22) |
| HSR / ZZZ / HI3 check-in | `https://sg-public-api.hoyolab.com` | ✅ | [`Constant.kt#L27-L33`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/util/Constant.kt#L27-L33) |
| WebView login | `https://m.hoyolab.com`, `https://www.hoyolab.com`, `https://account.hoyolab.com` | ✅ | [`CookieWebViewFragment.kt#L130`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/presentation/src/main/java/danggai/app/presentation/ui/cookie/CookieWebViewFragment.kt#L130), [`#L204-L205`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/presentation/src/main/java/danggai/app/presentation/ui/cookie/CookieWebViewFragment.kt#L204-L205), [`#L246`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/presentation/src/main/java/danggai/app/presentation/ui/cookie/CookieWebViewFragment.kt#L246) |
| China (not used) | `https://api-takumi.hoyoverse.com` | ✅ (ignored, D7) | [`Constant.kt#L15`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/util/Constant.kt#L15) |

⚠️ VERIFY: the game-record host was historically `bbs-api-os.hoyolab.com`; the reference repo
now uses `bbs-api-os.hoyoverse.com`. Use the `.hoyoverse.com` one; keep the `.hoyolab.com`
one out of the allowlist until a live test shows it is needed.

**Allowlist for `HoyolabConfig.allowedHosts` (exact host match, HTTPS only):**
`bbs-api-os.hoyoverse.com`, `sg-act-nap-api.hoyolab.com`, `sg-hk4e-api.hoyolab.com`,
`sg-public-api.hoyolab.com`. WebView navigation allowlist (separate, not for Dio):
`m.hoyolab.com`, `www.hoyolab.com`, `account.hoyolab.com`.

---

## 2. Dynamic Secret (DS)

✅ Source: [`CommonFunction.kt#L53-L73`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/presentation/src/main/java/danggai/app/presentation/util/CommonFunction.kt#L53-L73),
salt [`Constant.kt#L19`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/util/Constant.kt#L19).

```
t    = current Unix time in seconds
r    = 6 random lowercase letters a–z
hash = md5("salt=<OS_SALT>&t=<t>&r=<r>")   lowercase hex, 32 chars, zero-padded
DS   = "<t>,<r>,<hash>"
OS_SALT = 6cqshh5dhw73bzxn20oexa9k516chk7s
```

Known vector for tests (compute in 2.2 and pin it): `t=1700000000`, `r=abcdef` →
`md5("salt=6cqshh5dhw73bzxn20oexa9k516chk7s&t=1700000000&r=abcdef")`.

| Endpoint group | Sends DS? | Source |
|---|---|---|
| GI notes, HSR notes, record card, data switch | Yes | `@Header("DS")` in [`DailyNoteApi.kt`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/dailynote/remote/api/DailyNoteApi.kt), [`GetGameRecordCardApi.kt#L24`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/getgamerecordcard/remote/api/GetGameRecordCardApi.kt#L24) |
| ZZZ notes | **No** | [`DailyNoteApi.kt#L104-L109`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/dailynote/remote/api/DailyNoteApi.kt#L104-L109) |
| All check-in endpoints | **No** | [`CheckInApi.kt`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/checkin/remote/api/CheckInApi.kt) |

- The salt is a public client constant, not a secret (`CLAUDE.md` §7.7).
- China salt `xV8v4Qu54lUKrEYFZkJhB8cuOh9Asafs` exists in the repo; not used (D7).
- ⚠️ VERIFY: no other DS variant (e.g. one that also signs query/body) appears in the
  reference repo. If a live call returns a DS error, stop and research; do not guess a new
  algorithm.

---

## 3. Common headers

### 3.1 Game record group (GI/HSR notes, record card, data switch)
✅ [`DailyNoteApi.kt#L16-L24`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/dailynote/remote/api/DailyNoteApi.kt#L16-L24)

| Header | Value |
|---|---|
| `Accept` | `application/json, text/plain, */*` |
| `Content-Type` | `application/json;charset=UTF-8` |
| `Referer` | `https://webstatic-sea.hoyolab.com/` |
| `x-rpc-client_type` | `4` |
| `x-rpc-app_version` | `1.5.0` |
| `x-rpc-language` | `en-us` (reference hard-codes `ko-kr`) |
| `Cookie` | account cookie (§6) |
| `DS` | §2 |

⚠️ VERIFY: `x-rpc-app_version: 1.5.0` is very old; it still works in the reference app, but
HoYoLAB may start rejecting it. Keep it in `hoyolab_config.dart` so it is one-line to change.

### 3.2 ZZZ notes
✅ [`DailyNoteApi.kt#L91-L103`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/dailynote/remote/api/DailyNoteApi.kt#L91-L103):
`Accept: */*`, `Content-Type: application/json`, `Origin: https://act.hoyolab.com`,
`Referer: https://act.hoyolab.com/`, `x-rpc-client_type: 4`, `x-rpc-app_version: 1.5.0`,
`x-rpc-language`, `Cookie`. No DS.

### 3.3 Check-in group
✅ [`CheckInApi.kt#L14-L26`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/checkin/remote/api/CheckInApi.kt#L14-L26)

| Header | GI | HSR | ZZZ | HI3 |
|---|---|---|---|---|
| `Referer` | `https://act.hoyolab.com/` | `https://webstatic-sea.hoyolab.com/` | `https://act.hoyolab.com/` (+ `Origin`) | `https://webstatic-sea.hoyolab.com/` |
| `x-rpc-signgame` | — (only on retry: `hk4e`) | `hkrpg` | `zzz` | `bh3` |
| `x-rpc-platform` | `5` | — | `5` | — |
| `x-rpc-client_type` | — | — | `5` | — |
| Other | mobile Chrome `User-Agent` | — | `Timestamp: <unix seconds>` | — |

⚠️ VERIFY: the header sets differ per game in the reference repo, partly by history rather
than need. In 5.1, test a single shared header set (`x-rpc-signgame` per game,
`Referer`/`Origin` `https://act.hoyolab.com`) and keep per-game overrides only where a live
call proves them necessary.

---

## 4. Endpoints

### 4.1 Game record card (role/UID auto-detect) ✅
- **Source:** [`GetGameRecordCardApi.kt#L20-L25`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/getgamerecordcard/remote/api/GetGameRecordCardApi.kt#L20-L25),
  DTO [`GameRecordCard.kt`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/network/getgamerecordcard/entity/GameRecordCard.kt),
  usage [`NewHoyolabAccountViewModel.kt#L116-L121`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/presentation/src/main/java/danggai/app/presentation/ui/newaccount/NewHoyolabAccountViewModel.kt#L116-L121)
- **Request:** `GET https://bbs-api-os.hoyoverse.com/game_record/card/wapi/getGameRecordCard?uid=<hoyolab_uid>`
- **Headers:** §3.1 (with DS)
- `hoyolab_uid` comes from the cookie (§6.2).

```json
{
  "retcode": 0,
  "message": "OK",
  "data": {
    "list": [
      {
        "game_id": 2,
        "game_role_id": "800000001",
        "nickname": "Traveler",
        "region": "os_asia",
        "region_name": "Asia Server",
        "level": 58,
        "has_role": true,
        "is_public": true,
        "background_image": "https://…",
        "url": "",
        "data": [{ "name": "Days Active", "type": 1, "value": "512" }],
        "data_switches": [
          { "switch_id": 1, "is_public": true, "switch_name": "Show my Battle Chronicle on my profile" },
          { "switch_id": 3, "is_public": true, "switch_name": "Enable Real-Time Notes" }
        ],
        "h5_data_switches": []
      }
    ]
  }
}
```

- `game_id`: `1` HI3, `2` GI, `6` HSR, `8` ZZZ ([`Constant.kt#L73-L76`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/util/Constant.kt#L73-L76)).
- `region` is the server string to pass as `server=` (§5). Store it as-is.
- ⚠️ VERIFY: one card per game in the reference repo's usage. Whether an account with two
  roles in the same game returns two cards is unknown; the design expects that case
  (Kaz + Aiko in Genshin). Test with a real multi-role account in 3.4.
- ⚠️ VERIFY: the `switch_name` texts above are illustrative; only `switch_id` matters.

### 4.2 Change data switch (make Real-Time Notes public) ✅
- **Source:** [`ChangeDataSwitchApi.kt#L20-L29`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/changedataswitch/remote/api/ChangeDataSwitchApi.kt#L20),
  usage [`NewHoyolabAccountViewModel.kt#L584-L592`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/presentation/src/main/java/danggai/app/presentation/ui/newaccount/NewHoyolabAccountViewModel.kt#L584-L592)
- **Request:** `POST https://bbs-api-os.hoyoverse.com/game_record/card/wapi/changeDataSwitch?game_id=<id>&switch_id=<id>&is_public=true`
- **Headers:** §3.1 (with DS). No body.
- **Response:** `{ "retcode": 0, "message": "OK" }`
- Reference uses `game_id=2, switch_id=3` (GI Real-Time Notes) when notes return `10102`.
- ⚠️ VERIFY: switch ids for HSR (`game_id=6`) and ZZZ (`game_id=8`). Read them from
  `data_switches` in 4.1 instead of hard-coding, and **only call this after the user taps an
  explicit "Make notes visible" action** (it changes a setting on their HoYoLAB profile).

### 4.3 Genshin real-time notes ✅
- **Source:** [`DailyNoteApi.kt#L25-L31`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/dailynote/remote/api/DailyNoteApi.kt#L25-L31),
  DTOs [`GenshinDailyNote.kt`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/network/dailynote/entity/GenshinDailyNote.kt),
  [`Transformer.kt`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/network/dailynote/entity/Transformer.kt),
  [`TransformerTime.kt`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/network/dailynote/entity/TransformerTime.kt)
- **Request:** `GET https://bbs-api-os.hoyoverse.com/game_record/genshin/api/dailyNote?role_id=<uid>&server=<os_*>`
- **Headers:** §3.1 (with DS)

```json
{
  "retcode": 0,
  "message": "OK",
  "data": {
    "current_resin": 142,
    "max_resin": 200,
    "resin_recovery_time": "11520",
    "finished_task_num": 3,
    "total_task_num": 4,
    "is_extra_task_reward_received": false,
    "remain_resin_discount_num": 2,
    "resin_discount_num_limit": 3,
    "current_home_coin": 1840,
    "max_home_coin": 2400,
    "home_coin_recovery_time": "32400",
    "current_expedition_num": 5,
    "max_expedition_num": 5,
    "expeditions": [
      { "avatar_side_icon": "https://…", "status": "Finished", "remained_time": "0" },
      { "avatar_side_icon": "https://…", "status": "Ongoing", "remained_time": "8040" }
    ],
    "transformer": {
      "obtained": true,
      "recovery_time": { "Day": 4, "Hour": 6, "Minute": 0, "Second": 0, "reached": false },
      "wiki": "https://…",
      "noticed": false,
      "latest_job_id": "0"
    },
    "daily_task": {
      "total_num": 4,
      "finished_num": 3,
      "is_extra_task_reward_received": false,
      "task_rewards": [{ "status": "TaskRewardStatusFinished" }],
      "attendance_rewards": [{ "status": "AttendanceRewardStatusTakenAward", "progress": 2000 }],
      "attendance_visible": false,
      "stored_attendance": "0",
      "stored_attendance_refresh_countdown": 0
    },
    "calendar_url": "",
    "archon_quest_progress": { "list": [], "is_open_archon_quest": true, "is_finish_all_mainline": false, "is_finish_all_interchapter": false, "wiki_url": "" },
    "week_active_progress": null
  }
}
```

Mapping to the design (Phase 4):

| Dashboard item | Field(s) |
|---|---|
| Original Resin `142/200`, "Full in…" | `current_resin`, `max_resin`, `resin_recovery_time` (seconds until full, as **string**) |
| Realm Currency `1,840/2,400` | `current_home_coin`, `max_home_coin`, `home_coin_recovery_time` (seconds, string) |
| Daily Commissions `3/4`, bonus | `finished_task_num`, `total_task_num`, `is_extra_task_reward_received` |
| Weekly Bosses "2/3 discounts left" | `remain_resin_discount_num`, `resin_discount_num_limit` |
| Transformer "4d 6h" | `transformer.obtained`, `transformer.recovery_time.{Day,Hour,Minute,Second,reached}` |
| Expeditions `2 of 5 done` | `expeditions[].status` (`Finished`/`Ongoing`), `remained_time` (seconds, string) |

- ⚠️ VERIFY: expeditions have no character name, only `avatar_side_icon` (an image URL). The
  design shows names (Bennett, Fischl…) but we must not show game art. Plan: show
  "Expedition 1…5" with an initial-less neutral avatar, or derive a name from the icon file
  name (fragile). Decide in 4.4.
- ⚠️ VERIFY: `resin_recovery_time` is `"0"` when full; numeric strings everywhere. Parse
  defensively (`int.tryParse`, default 0).

### 4.4 Star Rail real-time notes ✅
- **Source:** [`DailyNoteApi.kt#L45-L51`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/dailynote/remote/api/DailyNoteApi.kt#L45-L51),
  DTO [`HonkaiSrDailyNote.kt`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/network/dailynote/entity/HonkaiSrDailyNote.kt)
- **Request:** `GET https://bbs-api-os.hoyoverse.com/game_record/hkrpg/api/note?role_id=<uid>&server=<prod_official_*>`
- **Headers:** §3.1 (with DS)

```json
{
  "retcode": 0,
  "message": "OK",
  "data": {
    "current_stamina": 168,
    "max_stamina": 240,
    "stamina_recover_time": 25920,
    "stamina_full_ts": 1763660400,
    "current_ts": 1763634480,
    "current_reserve_stamina": 1236,
    "is_reserve_stamina_full": false,
    "accepted_epedition_num": 4,
    "total_expedition_num": 4,
    "expeditions": [
      { "avatars": ["https://…"], "name": "Assignment name", "remaining_time": 0, "status": "Finished" },
      { "avatars": ["https://…"], "name": "Assignment name", "remaining_time": 13200, "status": "Ongoing" }
    ],
    "current_train_score": 400,
    "max_train_score": 500,
    "current_rogue_score": 9800,
    "max_rogue_score": 14000,
    "rogue_tourn_weekly_cur": 0,
    "rogue_tourn_weekly_max": 0,
    "rogue_tourn_weekly_unlocked": false,
    "rogue_tourn_exp_is_full": false,
    "grid_fight_weekly_cur": 0,
    "grid_fight_weekly_max": 0,
    "weekly_cocoon_cnt": 1,
    "weekly_cocoon_limit": 3,
    "period_score": 0
  }
}
```

| Dashboard item | Field(s) |
|---|---|
| Trailblaze Power `168/240` | `current_stamina`, `max_stamina`, `stamina_recover_time`, `stamina_full_ts` |
| Reserved Power `1,236/2,400` | `current_reserve_stamina`, `is_reserve_stamina_full` |
| Daily Training `400/500` | `current_train_score`, `max_train_score` |
| Echo of War `1/3` | `weekly_cocoon_cnt`, `weekly_cocoon_limit` |
| Simulated Universe `9,800/14k` | `current_rogue_score`, `max_rogue_score` |
| Assignments `1 of 4 done` | `expeditions[]` (`name`, `remaining_time` seconds as **int**, `status`), `accepted_epedition_num` (sic), `total_expedition_num` |

- Note the server typo `accepted_epedition_num` (kept by the reference repo on purpose).
- ⚠️ VERIFY: `stamina_recover_time` type. The DTO declares `String`, the JSON sample in
  other clients is a number. Parse both. Prefer `stamina_full_ts` (absolute) when > 0.
- ⚠️ VERIFY: reserved power max (2,400 in the design) is not in the response; it is a game
  constant. Keep it in config, flagged.
- `retcode` is typed `Int` here but `String` in the GI DTO; the Dart layer must accept both.
- ⚠️ VERIFY: `weekly_cocoon_cnt` is read as **remaining** Echo of War rewards (other open-source clients name it `remaining_weekly_discounts`), so the app models it as "left" like GI's weekly boss discounts. Confirm against a live account.
- Full time: the app uses `stamina_full_ts − current_ts` (server clock on both sides, so device clock skew does not matter) and falls back to `stamina_recover_time`.

### 4.5 Zenless Zone Zero real-time notes ✅
- **Source:** [`DailyNoteApi.kt#L104-L109`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/dailynote/remote/api/DailyNoteApi.kt#L104-L109),
  DTO [`ZZZDailyNote.kt`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/network/dailynote/entity/ZZZDailyNote.kt),
  enums [`Constant.kt#L107-L124`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/util/Constant.kt#L107-L124)
- **Request:** `GET https://sg-act-nap-api.hoyolab.com/event/game_record_zzz/api/zzz/note?role_id=<uid>&server=<prod_gf_*>`
- **Headers:** §3.2 (**no DS**)

```json
{
  "retcode": 0,
  "message": "OK",
  "data": {
    "energy": {
      "progress": { "max": 240, "current": 186 },
      "restore": 19440,
      "day_type": 1,
      "hour": 23,
      "minute": 52
    },
    "vitality": { "max": 400, "current": 300 },
    "vhs_sale": { "sale_state": "SaleStateDoing" },
    "card_sign": "CardSignDone",
    "bounty_commission": { "num": 2, "total": 4, "refresh_time": 205200 },
    "survey_points": { "num": 0, "total": 8000, "refresh_time": 205200 },
    "weekly_task": { "cur_point": 0, "max_point": 1300 },
    "abyss_refresh": 205200,
    "member_card": { "is_open": false, "member_card_state": "MemberCardStateNo", "exp_time": "0" },
    "temple_running": null,
    "cafe_state": null,
    "coffee": null,
    "is_sub": false
  }
}
```

| Dashboard item | Field(s) |
|---|---|
| Battery Charge `186/240`, "Full in…" | `energy.progress.current/max`, `energy.restore` (seconds until full), `energy.day_type/hour/minute` (full-at clock) |
| Engagement `300/400` | `vitality.current/max` |
| Scratch Card Done | `card_sign`: `CardSignNo` / `CardSignDone` |
| Video Store Open / Revenue ready | `vhs_sale.sale_state`: `SaleStateNo` / `SaleStateDoing` / `SaleStateDone` |
| Bounty Comm. `2/4` | `bounty_commission.num/total`, `refresh_time` (s) |
| Weekly progress (Ridu Weekly) | `weekly_task.cur_point/max_point` |

- ⚠️ VERIFY: `energy.restore` unit (reference treats it as seconds) and `day_type` meaning
  (reference: `1` = today; other values unknown, likely `2` = tomorrow).
- ⚠️ VERIFY: `bounty_commission`, `survey_points`, `weekly_task`, `member_card` are nullable
  (missing for low-level accounts). Hide the tile when null.
- Live (2026-11-21, owner account, IK 42): `bounty_commission` came back as `{num: 0, total: 0}` and `weekly_task` was absent. The app treats `total`/`max_point` of 0 the same as missing and hides the tile/row.
- ⚠️ VERIFY: design rows "Coffee Shop" and "Hollow Zero" map to `cafe_state` /
  `survey_points` at best; semantics unknown. Show only fields we understand.

### 4.6 Honkai Impact 3rd real-time notes ❌
Not present in the reference repo. No known overseas endpoint. **Confirms D3: HI3 is
check-in only and hidden from the dashboard.**

### 4.7 Daily check-in: claim ✅

| Game | Request | act_id | Source |
|---|---|---|---|
| GI | `POST https://sg-hk4e-api.hoyolab.com/event/sol/sign?lang=<lang>&act_id=e202102251931481` | `e202102251931481` | [`CheckInApi.kt#L27-L32`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/checkin/remote/api/CheckInApi.kt#L27-L32), [`Constant.kt#L22-L23`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/util/Constant.kt#L22-L23) |
| HSR | `POST https://sg-public-api.hoyolab.com/event/luna/os/sign?lang=<lang>&act_id=e202303301540311` | `e202303301540311` | [`CheckInApi.kt#L77-L82`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/checkin/remote/api/CheckInApi.kt#L77-L82), [`Constant.kt#L30-L31`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/util/Constant.kt#L30-L31) |
| HI3 | `POST https://sg-public-api.hoyolab.com/event/mani/sign?lang=<lang>&act_id=e202110291205111` | `e202110291205111` | [`CheckInApi.kt#L63-L68`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/checkin/remote/api/CheckInApi.kt#L63-L68), [`Constant.kt#L27-L28`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/util/Constant.kt#L27-L28) |
| ZZZ | `POST https://sg-public-api.hoyolab.com/event/luna/zzz/os/sign` with JSON body `{"lang":"<lang>","act_id":"e202406031448091"}` | `e202406031448091` | [`CheckInApi.kt#L104-L109`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/checkin/remote/api/CheckInApi.kt#L104-L109), [`CheckInRepositoryImpl.kt#L175-L180`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/checkin/repository/CheckInRepositoryImpl.kt#L175-L180), [`Constant.kt#L33-L34`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/util/Constant.kt#L33-L34) |

- **Headers:** §3.3. No DS. Cookie required.
- `lang`: `en-us` ([`CheckInWorker.kt#L815-L819`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/presentation/src/main/java/danggai/app/presentation/worker/CheckInWorker.kt#L815-L819)).
  ⚠️ VERIFY `id-id` for Indonesian reward names.

GI / HSR / HI3 response ([`CheckIn.kt#L3-L6`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/network/checkin/entity/CheckIn.kt#L3-L6)):
```json
{ "retcode": 0, "message": "OK",
  "data": { "code": "ok", "first_bind": false,
            "gt_result": { "risk_code": 0, "gt": "", "challenge": "", "success": 0, "is_risk": false } } }
```
Captcha case (still `retcode: 0`!):
```json
{ "retcode": 0, "message": "OK",
  "data": { "code": "ok", "first_bind": false,
            "gt_result": { "risk_code": 5001, "gt": "<key>", "challenge": "<key>", "success": 1, "is_risk": true } } }
```
ZZZ response ([`CheckInZZZ.kt#L3-L17`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/network/checkin/entity/CheckInZZZ.kt#L3-L17)):
the `gt_result` fields sit directly in `data`:
```json
{ "retcode": 0, "message": "OK",
  "data": { "code": "", "risk_code": 0, "gt": "", "challenge": "", "success": 0, "is_risk": false } }
```

**Reading the result** (reference logic, [`CheckInWorker.kt#L125-L205`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/presentation/src/main/java/danggai/app/presentation/worker/CheckInWorker.kt#L125-L205)):
1. `retcode` `-5003` or `2001` → already claimed today → `alreadyCheckedIn` (success for the UI).
2. `retcode` `0` and `is_risk == true` → **captcha** → `captchaRequired`; tell the user to
   open the official check-in page. Do not mark as claimed.
3. `retcode` `0` and `is_risk != true` → claimed.
4. `retcode` `-10002` → no role in this game → disable auto check-in for that game.
5. Anything else → failed, retry later.

- The reference retries GI with `x-rpc-challenge: <challenge>` + `x-rpc-signgame: hk4e`
  ([`CheckInApi.kt#L34-L54`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/checkin/remote/api/CheckInApi.kt#L34-L54)).
  **We do not do this.** Re-sending the captcha challenge without solving it is a captcha
  bypass attempt, which is a non-goal (`CLAUDE.md` §1, §7.9).
- Daily reset is **China midnight (`Asia/Shanghai`, UTC+8)**; the reference schedules its
  auto check-in for then ([`CheckInWorker.kt#L69-L73`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/presentation/src/main/java/danggai/app/presentation/worker/CheckInWorker.kt#L69-L73),
  [`CommonFunction.kt#L144-L168`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/presentation/src/main/java/danggai/app/presentation/util/CommonFunction.kt#L144-L168)).
  Our auto check-in time is user-chosen, but "today" must be computed in UTC+8.

### 4.8 Daily check-in: status + monthly rewards ⚠️ VERIFY (not in reference repo)
The design's reward calendar (Phase 5) needs today's status and the month's reward list.
The reference repo only claims; it never reads status or rewards. The endpoints below follow
the same base paths as 4.7 and are the commonly used ones in other open-source HoYoLAB
clients, **but they were not verified for this document**:

| Purpose | Request (per game base path from 4.7) |
|---|---|
| Status | `GET <base>/info?lang=<lang>&act_id=<act_id>` |
| Reward list | `GET <base>/home?lang=<lang>&act_id=<act_id>` |
| (Optional) re-sign info | `GET <base>/resign_info?lang=<lang>&act_id=<act_id>` (not planned) |

Expected shapes (unverified):
```json
{ "retcode": 0, "data": { "total_sign_day": 19, "today": "2026-11-20", "is_sign": false,
  "first_bind": false, "sign_cnt_missed": 1, "month_last_day": false } }
```
```json
{ "retcode": 0, "data": { "month": 11, "resign": false,
  "awards": [ { "icon": "https://…", "name": "Primogem", "cnt": 20 } ] } }
```
- Must be confirmed with a live request in **5.1** before any code depends on them.
- Reward `icon` URLs are official art: **do not display them** (design rule). Map by
  `name` to a Lucide icon, fall back to a generic gift icon.

---

## 5. Server / region mapping ✅
Source: [`Constant.kt#L50-L68`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/util/Constant.kt#L50-L68),
[`Server.kt`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/local/Server.kt).

| Region | GI `server=` | HSR `server=` | ZZZ `server=` |
|---|---|---|---|
| Asia | `os_asia` | `prod_official_asia` | `prod_gf_jp` |
| America | `os_usa` | `prod_official_usa` | `prod_gf_us` |
| Europe | `os_euro` | `prod_official_eur` | `prod_gf_eu` |
| TW/HK/MO | `os_cht` | `prod_official_cht` | `prod_gf_sg` |

- Preferred source of truth: `region` from the record card (4.1). Use the table only to label
  regions in the UI and to validate.
- The reference repo maps the ZZZ server with the HSR constants in one place
  ([`NewHoyolabAccountViewModel.kt` ~L177-L187](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/presentation/src/main/java/danggai/app/presentation/ui/newaccount/NewHoyolabAccountViewModel.kt#L177-L187));
  that looks like a bug there. We do not copy it.
- HI3 check-in needs no server.
- ⚠️ VERIFY: UID-prefix heuristics (e.g. GI `6xxxxxxxx` America, `7` Europe, `8` Asia,
  `9` TW/HK/MO) are **not** in the reference repo. Do not use them; rely on `region`.

---

## 6. Cookies

### 6.1 How the reference repo handles them ✅
- It stores and sends the **entire** cookie string the user pasted or the WebView captured
  ([`CheckInWorker.kt#L829-L851`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/presentation/src/main/java/danggai/app/presentation/worker/CheckInWorker.kt#L829-L851)).
- WebView: loads `https://m.hoyolab.com/#/timeline`, strips `; wv` from the User-Agent
  (Google sign-in blocks WebViews), and treats the user as logged in when the cookie for
  `https://www.hoyolab.com/` contains both `ltuid` and `ltoken`
  ([`CookieWebViewFragment.kt#L82-L84`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/presentation/src/main/java/danggai/app/presentation/ui/cookie/CookieWebViewFragment.kt#L82-L84),
  [`#L130-L135`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/presentation/src/main/java/danggai/app/presentation/ui/cookie/CookieWebViewFragment.kt#L130-L135),
  [`#L246`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/presentation/src/main/java/danggai/app/presentation/ui/cookie/CookieWebViewFragment.kt#L246)).
  It clears all WebView cookies before and after.
- Manual guide: log in at `https://www.hoyolab.com/`, run
  `javascript:document.write(document.cookie)` in the address bar, copy everything
  ([`how_to_get_hoyolab_cookie.md`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/how_to_get_hoyolab_cookie.md)).
  ⚠️ VERIFY: `document.cookie` cannot read HttpOnly cookies, and `ltoken_v2` /
  `cookie_token_v2` are typically HttpOnly. Our paste guide (design: 5 steps naming
  `ltuid_v2`, `ltoken_v2`, `cookie_token_v2`) should use the browser's DevTools →
  Application → Cookies instead. Confirm in 3.2.
- **Security note:** the reference app logs full request/response bodies
  (`HttpLoggingInterceptor.Level.BODY`, [`NetworkModule.kt#L43-L45`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/module/NetworkModule.kt#L43-L45)),
  which puts cookies in logcat. We must not (`CLAUDE.md` §7.4).

### 6.2 HoYoLAB UID from the cookie ✅
[`CommonFunction.kt#L75-L84`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/presentation/src/main/java/danggai/app/presentation/util/CommonFunction.kt#L75-L84):
split on `;`, trim, split each on the first `=`; take `ltuid`, else `ltuid_v2`, else
`account_id_v2`. (The reference splits on every `=`, which breaks values containing `=`;
we split on the first one only.)

### 6.3 Keys: v1 vs v2 ⚠️ VERIFY

| Key | Generation | Likely needed for |
|---|---|---|
| `ltuid`, `ltoken` | v1 (legacy) | game record, check-in (older accounts) |
| `ltuid_v2`, `ltoken_v2`, `ltmid_v2` | v2 | game record, check-in |
| `account_id_v2`, `account_mid_v2`, `cookie_token_v2` | v2 | account-level APIs |

- The reference repo never filters keys, so it does not tell us the minimum set.
- **Plan for 2.4 / 3.2:** keep the union of the keys above (and nothing else) in the vault,
  then measure in 3.2 which keys each endpoint actually needs, and shrink the set.
  Accept v1-only, v2-only and mixed cookies.

---

## 7. Retcodes ✅ (values) / app reaction (ours)
Source: [`Constant.kt#L87-L104`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/util/Constant.kt#L87-L104),
handling in [`NewHoyolabAccountViewModel.kt#L400-L500`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/presentation/src/main/java/danggai/app/presentation/ui/newaccount/NewHoyolabAccountViewModel.kt#L400-L500)
and [`CheckInWorker.kt`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/presentation/src/main/java/danggai/app/presentation/worker/CheckInWorker.kt).

| retcode | Reference name | Meaning | `AppException` | App reaction |
|---|---|---|---|---|
| `0` | SUCCESS | OK | — | Check `is_risk` on check-in (4.7) |
| `-100` | NOT_LOGGED_IN | Cookie missing/invalid | `cookieExpired` | Mark account expired, banner + notification |
| `10001` | NOT_LOGGED_IN_2 | Cookie invalid | `cookieExpired` | Same |
| `10103` | NOT_LOGGED_IN_3 | Cookie valid but not bound to this game account | `cookieExpired` ⚠️ | Same; message suggests re-login |
| `10104` | WRONG_ACCOUNT | UID does not belong to this cookie | `server` (noRoles) | Ask to re-detect roles |
| `10102` | DATA_NOT_PUBLIC | Real-Time Notes switched off | `server` ⚠️ (new case `notesPrivate`) | Offer "Make notes visible" (4.2) |
| `10101` | TOO_MANY_REQUESTS | Daily query limit for this cookie | `rateLimited` | Back off until tomorrow (UTC+8) |
| `-1004` | TOO_FAST | Requests too frequent | `rateLimited` | Retry with backoff |
| `-10002` | ACCOUNT_NOT_FOUND | No role in this game | `noRoles` | Hide/disable that game for the account |
| `1009` | CHARACTOR_INFO | Role info error | `server` | Show generic error |
| `-1` | INTERNAL_DATABASE_ERROR | Server-side error | `server` | Retry later |
| `-108` | INVALID_LANGUAGE | Bad `x-rpc-language` / `lang` | `server` | Fall back to `en-us` |
| `-502` | INVALID_INPUT_FORMAT | Bad params | `parse` | Bug: log (redacted) |
| `-5003` | CLAIMED_DAILY_REWARD | Already checked in | `alreadyCheckedIn` | Treat as success |
| `2001` | CHECKED_INTO_HOYOLAB | Already checked in (other path) | `alreadyCheckedIn` | Treat as success |
| `0` + `is_risk: true` | — | Geetest captcha | `captchaRequired` | "Open HoYoLAB" action; no retry |

- ⚠️ VERIFY: `CLAUDE.md` §3 lists the `AppException` cases; `10102` deserves its own case
  (`notesPrivate`) because it has a specific fix. Proposed change, needs owner approval in 2.4.
- ⚠️ VERIFY: game-record endpoints can also answer with a Geetest retcode (commonly `1034`
  in other clients). Not in the reference repo. Map unknown retcodes to `server(retcode)`
  and log (redacted) so we can learn them.
- HTTP status: the reference only distinguishes 2xx vs non-2xx; HoYoLAB normally returns
  HTTP 200 with a non-zero `retcode`.

---

## 8. Stamina recovery intervals ⚠️ VERIFY (not in reference repo)
Needed for "+1 every N min" and local extrapolation (4.1 in the roadmap):

| Game | Interval | Max (from API) |
|---|---|---|
| GI Original Resin | 8 min (480 s) | `max_resin` |
| HSR Trailblaze Power | 6 min (360 s) | `max_stamina` |
| ZZZ Battery Charge | 6 min (360 s) | `energy.progress.max` |

These are game-design constants, not API data. The reference repo has related constants
(`MAX_RESIN = 200`, `MAX_TRAILBLAZE_POWER = 300`, `MAX_BATTERY = 240`,
[`Constant.kt#L5-L7`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/domain/src/main/java/danggai/domain/util/Constant.kt#L5-L7)),
but always prefer the max from the response. Cross-check the intervals against the API's
"seconds until full" in 4.1.

---

## 9. Endpoints in the reference repo we do **not** use
| Endpoint | Why not |
|---|---|
| `POST /game_record/genshin/api/character` ([`CharacterApi.kt`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/character/remote/api/CharacterApi.kt)) | Character/talent widgets are a non-goal |
| `GET /game_record/hkrpg/api/rogue`, `/grid_fight` ([`DailyNoteApi.kt#L63-L89`](https://github.com/danggai/android_genshin_resin_widget/blob/9b04b0e18c217be4b5c8d7bc91a5bb3a08014c0c/data/src/main/java/danggai/data/network/dailynote/remote/api/DailyNoteApi.kt#L63-L89)) | Extra HSR modes not in the design |
| GitHub raw character list | Not HoYoLAB; off-domain |
| GI check-in retry with `x-rpc-challenge` | Captcha bypass, non-goal |

---

## 10. Open questions (owner / live checks)
1. **4.8 status + reward-list endpoints** are unverified. OK to confirm them with a live
   request using your own cookie in 5.1?
2. **Minimum cookie keys** (6.3): measured in 3.2 with your cookie, then the vault keeps only
   those.
3. **Expedition names** (4.3): the API gives only an image URL. Show "Expedition N" (no names),
   or something else?
4. **`notesPrivate` error case** (7): add it to `AppException`?
5. **Data switch** (4.2): OK that the app flips the "Real-Time Notes" public switch on the
   user's HoYoLAB profile, but only after an explicit tap?
6. **`x-rpc-app_version: 1.5.0`** (3.1): keep as is until a live call fails?
7. **Multi-role accounts** (4.1): need a test account with two roles in one game.
