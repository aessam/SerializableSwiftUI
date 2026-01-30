# SerializableSwiftUI

A framework for building native SwiftUI apps entirely from JSON. Define screens, layouts, data bindings, themes, and navigation in JSON files — the engine renders them as real SwiftUI views at runtime. Ship UI changes without App Store review.

Includes a built-in **visual editor** for designing screens, editing components, and previewing with live API data.

```
JSON files  ──>  ViewEngine  ──>  Native SwiftUI
                    │
              ThemeEngine
              ComponentRegistry
              ActionDispatcher
              DataContext (bindings)
```

## Quick Start

```bash
# Build & run
swift build
swift run SerializableSwiftUI

# Run tests
swift test
```

Requires **macOS 14+** and **Swift 5.9+**.

The app launches as a podcast browser — that's the demo payload. The real product is the engine and editor that any app can embed.

## Editor Mode

**Cmd+Shift+E** toggles a three-panel visual editor:

```
┌──────────┬────────────────────────────┬─────────────────────┐
│ NAVIGATOR│         CANVAS             │     INSPECTOR       │
│          │                            │                     │
│ Screens  │  Live Preview              │  Node Type: vstack  │
│  browse  │  (real API data or mock)   │  Props:             │
│  search  │                            │   spacing: [8]      │
│  detail  │  Tree Outline              │   alignment: [...]  │
│          │   ▾ screen                 │  Style: [card    ▾] │
│ Comps    │     ▾ scroll               │  Condition:         │
│ Theme    │       ▾ vstack  ← selected │  Inline Style:      │
└──────────┴────────────────────────────┴─────────────────────┘
```

**What you can do:**
- Browse screens, components, and theme in the navigator
- Click any node in the tree to inspect and edit its properties
- Type-aware property editors: dropdowns for alignment, binding pickers with autocomplete for data paths, visual action builders for navigation/API calls
- Style editor with preset picker and inline controls (font, colors, padding, dimensions)
- Live preview with **Mock** (instant, offline) or **Live** (real API calls) data modes
- Component editor with model-aware parameter picker showing all available fields
- Add/remove/duplicate nodes via context menu
- Create/delete screens from the navigator
- Theme editor for colors (light/dark adaptive), fonts, and presets
- **Cmd+S** saves all changes back to JSON files
- **Cmd+Z / Cmd+Shift+Z** for undo/redo

## Architecture

### Modules

```
PodcastData          Domain models + API client (with disk cache)
     │
ViewEngine           ViewNode, ViewRenderer, DataContext, ThemeEngine,
     │               ConditionEvaluator, TransformPipeline, ComponentRegistry
     │
ActionSystem         ActionDispatcher (navigate, API, setState, etc.)
     │
EditorUI             Visual editor: tree, inspector, preview, theme editor
     │
SerializableSwiftUI  App entry point, screen loader, JSON resources
```

### File Structure

```
Sources/
├── PodcastData/
│   ├── Podcast.swift              # Podcast model
│   ├── Episode.swift              # Episode model
│   └── PodcastService.swift       # iTunes API + disk response cache
├── ViewEngine/
│   ├── ViewNode.swift             # ViewNode, AnyCodableValue, ActionDefinition
│   ├── ViewRenderer.swift         # Renders ViewNode → SwiftUI
│   ├── DataContext.swift          # Reactive data binding with path resolution
│   ├── ThemeEngine.swift          # Colors, fonts, style presets
│   ├── ConditionEvaluator.swift   # Conditional rendering logic
│   ├── TransformPipeline.swift    # Value transforms (date, uppercase, etc.)
│   └── ComponentRegistry.swift    # Reusable component definitions
├── ActionSystem/
│   └── ActionDispatcher.swift     # Action handling + navigation
├── EditorUI/
│   ├── Model/
│   │   ├── EditableViewNode.swift    # Mutable @Observable tree node
│   │   ├── EditorDocument.swift      # Project state with undo support
│   │   ├── ProjectManager.swift      # Load/save JSON project files
│   │   ├── LiveDataCache.swift       # In-memory cache for API responses
│   │   ├── MockDataProvider.swift    # Sample data for preview
│   │   └── DataModelRegistry.swift   # Model field metadata for autocomplete
│   ├── Views/
│   │   ├── EditorRootView.swift      # Three-panel split view
│   │   ├── NavigatorView.swift       # Left: screens, components, theme tabs
│   │   ├── CanvasView.swift          # Center: preview + tree split
│   │   ├── TreeOutlineView.swift     # Recursive node tree with context menu
│   │   ├── LivePreviewView.swift     # ViewRenderer with mock/live data toggle
│   │   ├── InspectorView.swift       # Right: node property editing
│   │   ├── PropertyEditorView.swift  # Type-aware property forms
│   │   ├── StyleEditorView.swift     # Preset picker + inline style controls
│   │   ├── ActionBuilderView.swift   # Visual action composer
│   │   ├── BindingPickerView.swift   # $.path autocomplete
│   │   ├── ThemeEditorView.swift     # Color, font, preset editing
│   │   ├── ComponentEditorView.swift # Component editor with live preview
│   │   └── ScreenManagerView.swift   # Screen CRUD + app root tab editor
│   └── Util/
│       └── NodeTypeInfo.swift        # Node type metadata (icons, valid props)
└── SerializableSwiftUI/
    ├── SerializableSwiftUIApp.swift   # App entry point + editor mode toggle
    ├── JSONDrivenView.swift           # Runtime screen loader + navigation
    └── Resources/
        ├── app.json                   # Root tab configuration
        ├── theme.json                 # Colors, fonts, presets
        ├── components.json            # Reusable components
        ├── browse.json                # Browse screen
        ├── search.json                # Search screen
        ├── podcast_detail.json        # Podcast detail screen
        └── episode_detail.json        # Episode detail screen
```

## JSON Schema

### ViewNode

Every UI element is a `ViewNode`:

```json
{
  "type": "vstack",
  "id": "main_content",
  "style": "card",
  "inlineStyle": { "padding": 16, "backgroundColor": "surface" },
  "condition": "$.items | !empty",
  "props": { "spacing": 8, "alignment": "leading" },
  "children": [...]
}
```

| Field | Description |
|-------|-------------|
| `type` | Node type (see below) |
| `id` | Optional identifier |
| `style` | Name of a theme preset |
| `inlineStyle` | Direct style overrides |
| `condition` | Show/hide expression |
| `props` | Type-specific properties |
| `children` | Nested child nodes |

### Node Types

**Layout:** `vstack`, `hstack`, `zstack`, `scroll`, `lazy_vstack`, `lazy_hstack`, `grid`, `spacer`

**Content:** `text`, `image`, `divider`

**Interactive:** `button`, `text_field`, `search_bar`

**Data:** `list`, `component`

**Navigation:** `screen`, `navigation_stack`, `navigation_link`, `tab_view`

### Data Binding

Values starting with `$` resolve from the data context:

```json
{ "type": "text", "props": { "content": "$.podcast.trackName" } }
```

**Path syntax:**
- `$.key` — root level
- `$.key.nested.deep` — nested access
- `$.array.0` — array index
- `$.item` — current item in list template

**Transforms** via pipe:
```
$.releaseDate | date:MMM d, yyyy
$.items | count
$.name | uppercase
$.name | truncate:20
$.tags | join:,
$.value | default:N/A
$.duration | duration:mm:ss
```

### Conditions

Control rendering with expressions:

```json
{ "condition": "$.items | !empty" }
{ "condition": "$.count >= 5" }
{ "condition": "$.status == 'active'" }
{ "condition": "$.isLoggedIn" }
```

**Operators:** `==`, `!=`, `>`, `<`, `>=`, `<=`
**Pipes:** `| exists`, `| empty`, `| !empty`
**Truthy:** bare `$.path` checks for non-null, non-zero, non-empty

### Actions

```json
{
  "type": "button",
  "props": {
    "action": {
      "actionType": "navigate",
      "screen": "podcast_detail",
      "params": { "podcastId": "$.item.trackId" }
    }
  }
}
```

| Action Type | Fields | Description |
|-------------|--------|-------------|
| `navigate` | `screen`, `params` | Push screen onto navigation stack |
| `present` | `screen`, `params` | Show as modal sheet |
| `dismiss` | — | Close current modal |
| `api` | `endpoint`, `resultKey`, `params` | HTTP GET, store result in context |
| `setState` | `key`, `value` | Set value in data context |
| `custom` | `event`, `payload` | Fire custom event handler |
| `sequence` | `actions` | Run multiple actions in order |

### Theme

```json
{
  "colors": {
    "primary": "#007AFF",
    "background": { "light": "#FFFFFF", "dark": "#1C1C1E" }
  },
  "fonts": {
    "title": { "size": 20, "weight": "semibold" },
    "body": { "size": 17, "weight": "regular" }
  },
  "presets": {
    "card": { "padding": 12, "backgroundColor": "surface", "cornerRadius": 10 }
  }
}
```

**Style properties:** `font`, `foregroundColor`, `backgroundColor`, `padding`, `cornerRadius`, `width`, `height`, `maxWidth`, `maxHeight`, `shadow`, `opacity`, `clipShape`

Colors support adaptive light/dark via `{ "light": "...", "dark": "..." }`.

### Components

```json
{
  "components": {
    "podcast_card": {
      "parameters": ["podcast"],
      "body": {
        "type": "hstack",
        "props": { "spacing": 12 },
        "children": [
          { "type": "image", "props": { "source": "$.podcast.artworkUrl100" }, "style": "artwork_thumbnail" },
          { "type": "text", "props": { "content": "$.podcast.trackName" }, "style": "title" }
        ]
      }
    }
  }
}
```

Use with: `{ "type": "component", "props": { "name": "podcast_card", "parameters": { "podcast": "$.item" } } }`

### Screen with onLoad

```json
{
  "type": "screen",
  "props": {
    "title": "Browse",
    "onLoad": {
      "actionType": "api",
      "endpoint": "/search",
      "resultKey": "topPodcasts"
    }
  },
  "children": [...]
}
```

## Caching

**API responses** are cached to disk at `~/Library/Caches/SerializableSwiftUI/api_cache/`. Default TTL is 1 hour. Identical URLs return cached data with zero network calls.

**Editor live preview** uses an additional in-memory `LiveDataCache` per session — fetch a screen's data once, reuse it across preview refreshes, component randomization, and screen switches.

## Embedding in Your App

The engine is modular. To use it in your own app:

1. Add `ViewEngine`, `ActionSystem` as dependencies
2. Load your JSON screen definitions
3. Provide a `DataContext` with your data
4. Render with `ViewRenderer(node:context:)`

```swift
let node = try JSONDecoder().decode(ViewNode.self, from: screenJSON)
let context = DataContext(data: ["user": .dictionary([...])])

ViewRenderer(node: node, context: context) { action, ctx in
    // handle actions
}
```

The podcast app, theme, and editor are all optional — the engine stands alone.

## Tests

```bash
swift test
```

Covers: condition evaluation, transform pipeline, data context resolution, action dispatching, and ViewNode JSON round-tripping.

## License

MIT
