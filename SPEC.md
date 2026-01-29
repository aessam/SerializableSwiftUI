# SerializableSwiftUI — Specification

## 1. Overview

A SwiftUI iOS application that renders its entire UI — screens, navigation, tabs, cells, and layout — from JSON view definitions. The app uses the iTunes Podcast Search API as its data source. All views are described declaratively in bundled JSON files, with data bindings, conditional rendering, and composable reusable components.

**Target:** iOS 17+, SwiftUI, Swift 5.9+

---

## 2. Architecture

```
┌─────────────────────────────────────────────────┐
│                    App Shell                     │
│  (Bootstraps from root JSON, no hardcoded UI)    │
├─────────────────────────────────────────────────┤
│              JSON View Engine                     │
│  ┌───────────┐ ┌───────────┐ ┌────────────────┐ │
│  │  Parser    │ │ Resolver  │ │   Renderer     │ │
│  │ (Decode)   │ │ (Bindings)│ │ (SwiftUI View) │ │
│  └───────────┘ └───────────┘ └────────────────┘ │
├─────────────────────────────────────────────────┤
│              Data Layer                           │
│  ┌───────────────┐  ┌─────────────────────────┐ │
│  │ Podcast Models │  │  iTunes API Service     │ │
│  └───────────────┘  └─────────────────────────┘ │
├─────────────────────────────────────────────────┤
│              Theme / Style System                 │
│  (Named presets loaded from JSON)                │
└─────────────────────────────────────────────────┘
```

### 2.1 Key Modules

| Module | Responsibility |
|---|---|
| **ViewEngine** | Parses JSON into a view node tree, resolves bindings against a data context, renders SwiftUI views |
| **DataService** | Fetches podcast data from the iTunes Search API, exposes results as `@Observable` models |
| **ThemeEngine** | Loads named style presets from a `theme.json` file; views reference presets by name |
| **ActionDispatcher** | Handles actions (navigate, API call, custom event) triggered by user interaction |
| **ComponentRegistry** | Stores reusable named components defined in JSON; supports parameterized composition |

---

## 3. iTunes Podcast API

Base URL: `https://itunes.apple.com`

| Endpoint | Use |
|---|---|
| `/search?term={query}&media=podcast` | Search podcasts |
| `/lookup?id={id}` | Podcast detail |
| `/lookup?id={id}&entity=podcastEpisode` | Episodes for a podcast |
| `/search?term=podcast&genreId={id}&limit=25` | Browse by genre |

### 3.1 Data Models (Swift)

```swift
struct PodcastSearchResult: Codable {
    let resultCount: Int
    let results: [Podcast]
}

struct Podcast: Codable, Identifiable {
    let trackId: Int
    let trackName: String
    let artistName: String
    let artworkUrl600: String?
    let collectionViewUrl: String?
    let feedUrl: String?
    let primaryGenreName: String?
    let genres: [String]?
    let trackCount: Int?
    let releaseDate: String?
    let contentAdvisoryRating: String?

    var id: Int { trackId }
}

struct Episode: Codable, Identifiable {
    let trackId: Int
    let trackName: String
    let description: String?
    let releaseDate: String?
    let trackTimeMillis: Int?
    let episodeUrl: String?

    var id: Int { trackId }
}
```

---

## 4. JSON View System

### 4.1 View Node Schema

Every UI element is a **ViewNode** — a recursive, typed JSON object:

```json
{
  "type": "vstack",
  "id": "optional-unique-id",
  "style": "presetName",
  "inlineStyle": { ... },
  "condition": "$.podcast.isExplicit == true",
  "children": [ ... ],
  "props": { ... }
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `type` | string | yes | The component type (see §4.2) |
| `id` | string | no | Unique identifier for the node |
| `style` | string | no | Named theme preset to apply |
| `inlineStyle` | object | no | Override specific style properties |
| `condition` | string | no | JSONPath expression; node renders only if truthy |
| `children` | [ViewNode] | no | Child nodes (for containers) |
| `props` | object | no | Type-specific properties |

### 4.2 Primitive Components

#### Layout

| Type | Props | Description |
|---|---|---|
| `vstack` | `spacing`, `alignment` | Vertical stack |
| `hstack` | `spacing`, `alignment` | Horizontal stack |
| `zstack` | `alignment` | Overlay stack |
| `scroll` | `axis` (`horizontal`/`vertical`) | ScrollView |
| `list` | `items` (JSONPath), `itemTemplate` (ViewNode), `separator` | ForEach over data |
| `lazy_vstack` | `spacing`, `alignment` | Lazy vertical stack |
| `lazy_hstack` | `spacing`, `alignment` | Lazy horizontal stack |
| `spacer` | `minLength` | Flexible space |
| `grid` | `columns`, `spacing` | LazyVGrid |

#### Content

| Type | Props | Description |
|---|---|---|
| `text` | `content` (string/binding), `lineLimit` | Text label |
| `image` | `source` (url binding or system name), `resizable`, `aspectRatio`, `contentMode` | Image (async for URLs) |
| `divider` | — | Visual separator |

#### Interactive

| Type | Props | Description |
|---|---|---|
| `button` | `label` (ViewNode), `action` (Action) | Tappable button |
| `navigation_link` | `destination` (screen ref), `label` (ViewNode) | Push navigation |
| `text_field` | `placeholder`, `binding` (two-way data path) | Text input |
| `search_bar` | `placeholder`, `binding`, `onSubmit` (Action) | Search field |

#### Container / Navigation

| Type | Props | Description |
|---|---|---|
| `tab_view` | `tabs` (array of Tab objects) | Tab bar |
| `navigation_stack` | `root` (ViewNode) | Navigation container |
| `screen` | `title`, `body` (ViewNode), `toolbar` (ViewNode) | A full screen |
| `sheet` | `content` (ViewNode) | Modal sheet |

#### Custom / Composite

| Type | Props | Description |
|---|---|---|
| `component` | `name`, `parameters` | Reference to a reusable component |

### 4.3 Reusable Components

Components are defined in a top-level `components` section and referenced by name:

```json
{
  "components": {
    "podcast_card": {
      "parameters": ["podcast"],
      "body": {
        "type": "hstack",
        "props": { "spacing": 12 },
        "children": [
          {
            "type": "image",
            "props": {
              "source": "$.podcast.artworkUrl600",
              "contentMode": "fill"
            },
            "style": "artwork_thumbnail"
          },
          {
            "type": "vstack",
            "props": { "alignment": "leading", "spacing": 4 },
            "children": [
              { "type": "text", "props": { "content": "$.podcast.trackName" }, "style": "title" },
              { "type": "text", "props": { "content": "$.podcast.artistName" }, "style": "subtitle" }
            ]
          }
        ]
      }
    }
  }
}
```

Usage:

```json
{
  "type": "component",
  "props": {
    "name": "podcast_card",
    "parameters": { "podcast": "$.item" }
  }
}
```

---

## 5. Data Binding

### 5.1 Syntax

Bindings use **JSONPath** notation prefixed with `$`:

| Expression | Resolves to |
|---|---|
| `$.podcast.trackName` | Value of `trackName` on the podcast object in context |
| `$.searchResults.results` | The results array |
| `$.item.trackId` | Current item's trackId (inside a `list`) |
| `$.env.searchQuery` | An environment/state value |

### 5.2 Resolution Rules

1. Props with string values starting with `$` are treated as bindings
2. Literal strings that need a leading `$` must be escaped: `\\$`
3. Bindings are resolved against a **DataContext** — a dictionary passed down the view tree
4. `list` components inject each element as `$.item` (and index as `$.index`) into child context

### 5.3 Transforms

Bindings can include a pipe-delimited transform chain:

```
$.episode.releaseDate | date:MMM d, yyyy
$.episode.trackTimeMillis | duration:mm:ss
$.podcast.trackName | uppercase
$.podcast.genres | join:,
$.podcast.trackCount | default:0
```

Built-in transforms:

| Transform | Description |
|---|---|
| `date:<format>` | Format ISO 8601 date string |
| `duration:<format>` | Format milliseconds to time |
| `uppercase` | Uppercase string |
| `lowercase` | Lowercase string |
| `join:<separator>` | Join array with separator |
| `default:<value>` | Fallback if nil |
| `truncate:<length>` | Truncate with ellipsis |
| `count` | Array count |

---

## 6. Conditions

Conditions are JSONPath expressions evaluated as booleans:

```json
{
  "condition": "$.podcast.contentAdvisoryRating == 'Explicit'"
}
```

Supported operators: `==`, `!=`, `>`, `<`, `>=`, `<=`, `exists`, `empty`, `!empty`

```json
"condition": "$.podcast.feedUrl | exists"
"condition": "$.searchResults.results | !empty"
"condition": "$.podcast.trackCount > 100"
```

A node with a falsy condition is not rendered (returns `EmptyView`).

---

## 7. Theme & Style System

### 7.1 Theme File (`theme.json`)

```json
{
  "colors": {
    "primary": "#007AFF",
    "secondary": "#8E8E93",
    "background": "#FFFFFF",
    "surface": "#F2F2F7",
    "destructive": "#FF3B30",
    "text_primary": "#000000",
    "text_secondary": "#6C6C70"
  },
  "fonts": {
    "largeTitle": { "size": 34, "weight": "bold", "design": "default" },
    "title": { "size": 20, "weight": "semibold" },
    "body": { "size": 17, "weight": "regular" },
    "caption": { "size": 13, "weight": "regular" },
    "footnote": { "size": 12, "weight": "regular" }
  },
  "presets": {
    "title": {
      "font": "title",
      "foregroundColor": "text_primary"
    },
    "subtitle": {
      "font": "caption",
      "foregroundColor": "text_secondary"
    },
    "artwork_thumbnail": {
      "width": 60,
      "height": 60,
      "cornerRadius": 8
    },
    "artwork_large": {
      "width": 200,
      "height": 200,
      "cornerRadius": 12,
      "shadow": { "radius": 4, "y": 2, "color": "#00000033" }
    },
    "card": {
      "padding": 12,
      "backgroundColor": "surface",
      "cornerRadius": 10
    },
    "screen_body": {
      "padding": 16,
      "backgroundColor": "background"
    }
  }
}
```

### 7.2 Inline Style Properties

Any preset property can be overridden per-node via `inlineStyle`:

| Property | Type | Description |
|---|---|---|
| `font` | string (preset name) | Font from theme |
| `foregroundColor` | string (color name or hex) | Text/icon color |
| `backgroundColor` | string | Background color |
| `padding` | number or `{top,bottom,leading,trailing}` | Padding |
| `cornerRadius` | number | Corner rounding |
| `width`, `height` | number or `"infinity"` | Frame dimensions |
| `maxWidth`, `maxHeight` | number or `"infinity"` | Max frame |
| `shadow` | `{radius, x, y, color}` | Drop shadow |
| `opacity` | number (0-1) | Opacity |
| `clipShape` | `"circle"` / `"roundedRect"` | Clip mask |

---

## 8. Actions

### 8.1 Action Schema

```json
{
  "actionType": "navigate",
  "screen": "podcast_detail",
  "params": { "podcastId": "$.item.trackId" }
}
```

### 8.2 Action Types

| actionType | Fields | Description |
|---|---|---|
| `navigate` | `screen`, `params` | Push a screen onto the navigation stack |
| `present` | `screen`, `params` | Present a sheet/modal |
| `dismiss` | — | Dismiss current sheet |
| `api` | `endpoint`, `params`, `resultKey` | Call iTunes API and store result |
| `setState` | `key`, `value` | Set a state/environment value |
| `custom` | `event`, `payload` | Dispatch a named event to Swift handler |
| `sequence` | `actions` (array) | Execute actions in order |

### 8.3 Custom Events

Custom events allow JSON-defined views to call into native Swift code:

```json
{
  "actionType": "custom",
  "event": "openExternalUrl",
  "payload": { "url": "$.podcast.collectionViewUrl" }
}
```

Swift side registers handlers:

```swift
engine.registerEventHandler("openExternalUrl") { payload in
    guard let urlString = payload["url"] as? String,
          let url = URL(string: urlString) else { return }
    UIApplication.shared.open(url)
}
```

---

## 9. Screens

### 9.1 Screen Definitions

Each screen is a JSON file (or a keyed entry in a `screens.json`):

| Screen | File | Data Context |
|---|---|---|
| App Root | `app.json` | — |
| Browse | `browse.json` | Genre-based podcast lists |
| Search | `search.json` | Search results |
| Podcast Detail | `podcast_detail.json` | Single podcast + episodes |
| Episode Detail | `episode_detail.json` | Single episode |

### 9.2 App Root (`app.json`)

```json
{
  "type": "tab_view",
  "props": {
    "tabs": [
      {
        "title": "Browse",
        "icon": "square.grid.2x2",
        "screen": "browse"
      },
      {
        "title": "Search",
        "icon": "magnifyingglass",
        "screen": "search"
      }
    ]
  }
}
```

### 9.3 Screen Resolution

When an action references `"screen": "podcast_detail"`, the engine:

1. Loads the view definition from `podcast_detail.json`
2. Creates a new DataContext with the action's `params`
3. Fetches any required API data (if the screen specifies an `onLoad` action)
4. Renders the view tree

Screen files may include an `onLoad` action:

```json
{
  "type": "screen",
  "props": {
    "title": "$.podcast.trackName",
    "onLoad": {
      "actionType": "api",
      "endpoint": "/lookup",
      "params": { "id": "$.podcastId", "entity": "podcastEpisode" },
      "resultKey": "episodes"
    }
  },
  "children": [ ... ]
}
```

---

## 10. File Structure

```
SerializableSwiftUI/
├── App/
│   └── SerializableSwiftUIApp.swift          # Entry point
├── Engine/
│   ├── ViewNode.swift                        # Codable view node model
│   ├── ViewRenderer.swift                    # ViewNode → SwiftUI View
│   ├── DataContext.swift                      # Binding resolution
│   ├── ConditionEvaluator.swift              # Condition parsing & eval
│   ├── TransformPipeline.swift               # Value transforms
│   ├── ActionDispatcher.swift                # Action execution
│   ├── ComponentRegistry.swift               # Reusable component store
│   └── ThemeEngine.swift                     # Style preset resolution
├── Data/
│   ├── PodcastService.swift                  # iTunes API client
│   ├── Podcast.swift                         # Data models
│   └── Episode.swift
├── Views/
│   └── JSONDrivenView.swift                  # Top-level SwiftUI wrapper
├── Resources/
│   ├── theme.json
│   ├── components.json                       # Shared reusable components
│   ├── app.json                              # Root tab view
│   ├── browse.json
│   ├── search.json
│   ├── podcast_detail.json
│   └── episode_detail.json
├── Tests/
│   ├── ViewNodeDecodingTests.swift
│   ├── DataContextTests.swift
│   ├── ConditionEvaluatorTests.swift
│   ├── TransformPipelineTests.swift
│   └── ActionDispatcherTests.swift
└── SPEC.md
```

---

## 11. Engine Lifecycle

```
1. App launches
2. ThemeEngine loads theme.json
3. ComponentRegistry loads components.json
4. ViewEngine loads app.json → renders root TabView
5. User taps "Browse" tab → loads browse.json
6. browse.json has onLoad → ActionDispatcher calls iTunes API
7. API result stored in DataContext under resultKey
8. ViewRenderer walks the node tree:
   a. Evaluate condition → skip if false
   b. Resolve style preset + inline overrides
   c. Resolve prop bindings against DataContext
   d. For `list`: iterate items, inject $.item context per child
   e. For `component`: look up in registry, pass parameters
   f. Render SwiftUI view
9. User taps a podcast → navigate action fires
10. Engine loads podcast_detail.json with params, repeat from step 6
```

---

## 12. Constraints & Non-Goals (v1)

- **No audio playback** — out of scope
- **No persistence / offline** — all data fetched live
- **No remote JSON fetching** — bundled files only
- **No hot-reload** — restart to see JSON changes
- **No animations defined in JSON** — use SwiftUI defaults
- **No two-way binding for complex forms** — only search text field

---

## 13. Testing Strategy

| Layer | What to Test |
|---|---|
| **Decoding** | All ViewNode types round-trip from JSON |
| **Binding** | JSONPath resolution, transforms, escaping |
| **Conditions** | All operators, edge cases (nil, missing keys) |
| **Actions** | Navigation, API calls, setState, sequences |
| **Components** | Parameter passing, nested components |
| **Integration** | Full screen render from JSON with mock data |
