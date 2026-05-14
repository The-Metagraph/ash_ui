#define SDL_MAIN_USE_CALLBACKS 1
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#if defined(DUI_HAS_SDL3_IMAGE)
#include <SDL3_image/SDL_image.h>
#endif
#if defined(DUI_HAS_SDL3_TTF)
#include <SDL3_ttf/SDL_ttf.h>
#endif
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_WINDOWS 16
#define MAX_DRAWS 512
#define MAX_FONTS 16
#define MAX_TEXT_CACHE 256
#define MAX_IMAGE_CACHE 128
#define MAX_INTERACTION_EVENTS 128
#define MAX_LINE 4096

typedef struct {
  Uint8 r;
  Uint8 g;
  Uint8 b;
  Uint8 a;
} dui_color;

typedef struct {
  char window_id[128];
  char title[128];
  int x;
  int y;
  int width;
  int height;
  SDL_Window *window;
  SDL_Renderer *renderer;
} dui_window;

typedef struct {
  char window_id[128];
  char widget_id[128];
  char draw_kind[64];
  char kind[64];
  char family[64];
  char bg[64];
  char fg[64];
  char border[64];
  char variant[64];
  char semantic_role[64];
  char attrs[128];
  char content[256];
  char image_source[256];
  char shortcut[64];
  char shortcut_intent[64];
  char click_intent[64];
  char submit_intent[64];
  char selection_intent[64];
  char command_intent[64];
  char close_intent[64];
  char navigation_intent[64];
  char window_identity[64];
  char overlay_role[64];
  char selection_mode[32];
  int x;
  int y;
  int width;
  int height;
  int clip;
  int clip_x;
  int clip_y;
  int clip_width;
  int clip_height;
  int focusable;
  int disabled;
  int focused;
  int selected;
  int checked;
  int active;
  int open;
  int current;
  int loading;
  int child_count;
  int item_count;
  int row_count;
  int column_count;
  int series_count;
  int current_index;
  int selected_index;
  int value;
  int min_value;
  int max_value;
  int content_length;
  int dismissible;
  int paused;
} dui_draw;

typedef struct {
  dui_window windows[MAX_WINDOWS];
  int window_count;
  dui_draw draws[MAX_DRAWS];
  int draw_count;
} dui_frame;

typedef struct {
  char type[32];
  char window_id[128];
  char widget_id[128];
  char focus_target[128];
  char key[32];
  char modifiers[64];
  char button[16];
  int x;
  int y;
  int delta_x;
  int delta_y;
  char intent[64];
} dui_interaction_event;

typedef struct {
  int total_events;
  int scripted_events;
  int live_events;
  int focus_changes;
  int command_activations;
  int selection_changes;
  int submit_actions;
  int scroll_events;
  int overlay_transitions;
  int window_activations;
  int multiwindow_focus_transfers;
  char active_window_id[128];
  char focused_widget_id[128];
  char last_command_widget_id[128];
  char last_command_intent[64];
  char last_selected_widget_id[128];
  char last_submit_widget_id[128];
  char last_scroll_widget_id[128];
} dui_interaction_summary;

typedef struct {
  int size;
  int style;
#if defined(DUI_HAS_SDL3_TTF)
  TTF_Font *font;
#endif
} dui_font_entry;

typedef struct {
  char key[768];
  int width;
  int height;
#if defined(DUI_HAS_SDL3_TTF)
  SDL_Texture *texture;
#endif
} dui_text_cache_entry;

typedef struct {
  char source[512];
  int width;
  int height;
#if defined(DUI_HAS_SDL3_IMAGE)
  SDL_Texture *texture;
#endif
} dui_image_cache_entry;

typedef struct {
  int text_backend_ready;
  int image_backend_ready;
  char font_path[512];
  dui_font_entry fonts[MAX_FONTS];
  int font_count;
  dui_text_cache_entry text_cache[MAX_TEXT_CACHE];
  int text_cache_count;
  dui_image_cache_entry image_cache[MAX_IMAGE_CACHE];
  int image_cache_count;
} dui_resources;

typedef struct {
  dui_frame frame;
  dui_resources resources;
  dui_interaction_event scripted_events[MAX_INTERACTION_EVENTS];
  int scripted_event_count;
  int next_scripted_event_index;
  int last_pointer_x;
  int last_pointer_y;
  dui_interaction_summary interaction_summary;
  int linger_ms;
  Uint64 start_ticks;
  int needs_redraw;
  int shutdown_requested;
} dui_app;

static void decode_value(char *value);
static int parse_frame_script(const char *path, dui_frame *frame);
static int parse_interaction_script(const char *path, dui_app *app);
static int parse_attrs(char *line, char attrs[][2][256], int max_attrs);
static void copy_attr(char *dest, size_t dest_size, char attrs[][2][256], int count,
                      const char *key, const char *fallback);
static int int_attr(char attrs[][2][256], int count, const char *key, int fallback);
static void render_window(dui_app *app, dui_frame *frame, int window_index);
static void destroy_frame_windows(dui_frame *frame);
static void init_resource_support(dui_app *app);
static void destroy_resource_support(dui_app *app);
static void print_probe(void);
static dui_color named_color(const char *name, Uint8 alpha);
static SDL_Color as_sdl_color(dui_color color);
static void use_color(SDL_Renderer *renderer, dui_color color);
static void fill_rect(SDL_Renderer *renderer, SDL_FRect rect, dui_color color);
static void stroke_rect(SDL_Renderer *renderer, SDL_FRect rect, dui_color color);
static void fill_inset_rect(SDL_Renderer *renderer, SDL_FRect rect, float inset, dui_color color);
static void draw_text_bands(SDL_Renderer *renderer, SDL_FRect rect, int content_length,
                            dui_color color, int emphasized);
static void draw_text_content(dui_app *app, SDL_Renderer *renderer, const dui_draw *draw,
                              SDL_FRect rect, dui_color color, int emphasized);
static void draw_image_content(dui_app *app, SDL_Renderer *renderer, const dui_draw *draw,
                               SDL_FRect rect);
static void draw_item_rows(SDL_Renderer *renderer, SDL_FRect rect, int count, int current_index,
                           int selected_index, dui_color base, dui_color highlight);
static void draw_table_grid(SDL_Renderer *renderer, SDL_FRect rect, int columns, int rows,
                            dui_color stroke, dui_color highlight);
static void draw_progress_bar(SDL_Renderer *renderer, SDL_FRect rect, int value, int max_value,
                              dui_color track, dui_color fill);
static void draw_surface_shell(SDL_Renderer *renderer, SDL_FRect rect, dui_color fill,
                               dui_color stroke, const char *border_kind, int focused,
                               int disabled);
static void render_draw_operation(dui_app *app, SDL_Renderer *renderer, const dui_draw *draw);
static int copy_window_id_for_native_window(dui_frame *frame, SDL_WindowID native_window_id,
                                            char *dest, size_t dest_size);
static int is_focusable_draw(const dui_draw *draw);
static int point_in_draw(const dui_draw *draw, int x, int y);
static dui_draw *hit_test_draw(dui_frame *frame, const char *window_id, int x, int y);
static dui_draw *find_draw_by_widget_id(dui_frame *frame, const char *window_id,
                                        const char *widget_id);
static void focus_draw(dui_app *app, const char *window_id, const char *widget_id);
static void activate_draw(dui_app *app, dui_draw *draw);
static void select_draw_index(dui_app *app, dui_draw *draw, int index);
static void close_overlay_draws(dui_app *app, const char *window_id);
static void apply_scroll(dui_app *app, dui_draw *draw, int delta_y);
static void apply_keyboard_event(dui_app *app, const dui_interaction_event *event);
static void apply_pointer_button_event(dui_app *app, const dui_interaction_event *event);
static void apply_pointer_hover_event(dui_app *app, const dui_interaction_event *event);
static void apply_wheel_event(dui_app *app, const dui_interaction_event *event);
static void apply_window_activation_event(dui_app *app, const dui_interaction_event *event);
static void apply_focus_event(dui_app *app, const dui_interaction_event *event);
static void apply_interaction_event(dui_app *app, const dui_interaction_event *event,
                                    int scripted);
static int string_contains_token(const char *attrs, const char *token);
static const char *default_font_path(void);
static int file_exists(const char *path);
#if defined(DUI_HAS_SDL3_TTF)
static int text_style_flags(const dui_draw *draw);
static int text_font_size(const dui_draw *draw, int emphasized);
static TTF_Font *load_font(dui_app *app, int size, int style);
static SDL_Texture *text_texture_for(dui_app *app, SDL_Renderer *renderer, const dui_draw *draw,
                                     dui_color color, int emphasized, int *width, int *height);
#endif
#if defined(DUI_HAS_SDL3_IMAGE)
static SDL_Texture *image_texture_for(dui_app *app, SDL_Renderer *renderer, const char *source,
                                      int *width, int *height);
#endif

static void print_probe(void) {
  printf(
      "{\"host\":\"desktop_ui_sdl3_host\",\"status\":\"visible_frame_ready\","
      "\"launch_ready\":false,\"visible_runner_ready\":true,"
      "\"backend\":\"compiled_sdl3_host\",\"compiled_with\":\"SDL3 %d.%d.%d\","
      "\"native_text_ready\":%s,\"native_image_ready\":%s,"
      "\"text_mode\":\"%s\",\"image_mode\":\"%s\"}\n",
      SDL_MAJOR_VERSION, SDL_MINOR_VERSION, SDL_MICRO_VERSION,
#if defined(DUI_HAS_SDL3_TTF)
      "true",
#else
      "false",
#endif
#if defined(DUI_HAS_SDL3_IMAGE)
      "true",
#else
      "false",
#endif
#if defined(DUI_HAS_SDL3_TTF)
      "native_sdl3_ttf",
#else
      "fallback_text_bands",
#endif
#if defined(DUI_HAS_SDL3_IMAGE)
      "native_sdl3_image"
#else
      "fallback_image_fill"
#endif
  );
}

static void init_resource_support(dui_app *app) {
  memset(&app->resources, 0, sizeof(app->resources));

#if defined(DUI_HAS_SDL3_TTF)
  if (TTF_Init()) {
    const char *font_path = default_font_path();
    if (font_path != NULL) {
      strncpy(app->resources.font_path, font_path, sizeof(app->resources.font_path) - 1);
      app->resources.font_path[sizeof(app->resources.font_path) - 1] = '\0';
      app->resources.text_backend_ready = 1;
    } else {
      fprintf(stderr, "desktop_ui SDL3 host: no usable font path found, falling back to bands\n");
    }
  } else {
    fprintf(stderr, "desktop_ui SDL3 host: TTF_Init failed: %s\n", SDL_GetError());
  }
#endif

#if defined(DUI_HAS_SDL3_IMAGE)
  app->resources.image_backend_ready = 1;
#endif
}

static void destroy_resource_support(dui_app *app) {
#if defined(DUI_HAS_SDL3_TTF)
  for (int i = 0; i < app->resources.text_cache_count; i++) {
    if (app->resources.text_cache[i].texture != NULL) {
      SDL_DestroyTexture(app->resources.text_cache[i].texture);
      app->resources.text_cache[i].texture = NULL;
    }
  }

  for (int i = 0; i < app->resources.font_count; i++) {
    if (app->resources.fonts[i].font != NULL) {
      TTF_CloseFont(app->resources.fonts[i].font);
      app->resources.fonts[i].font = NULL;
    }
  }

  if (TTF_WasInit()) {
    TTF_Quit();
  }
#endif

#if defined(DUI_HAS_SDL3_IMAGE)
  for (int i = 0; i < app->resources.image_cache_count; i++) {
    if (app->resources.image_cache[i].texture != NULL) {
      SDL_DestroyTexture(app->resources.image_cache[i].texture);
      app->resources.image_cache[i].texture = NULL;
    }
  }
#endif
}

SDL_AppResult SDL_AppInit(void **appstate, int argc, char **argv) {
  dui_app *app = (dui_app *)calloc(1, sizeof(dui_app));
  const char *frame_script = NULL;
  const char *interaction_script = NULL;
  *appstate = app;

  if (app == NULL) {
    fprintf(stderr, "unable to allocate desktop_ui SDL3 app state\n");
    return SDL_APP_FAILURE;
  }

  app->linger_ms = 1500;

  for (int i = 1; i < argc; i++) {
    if (strcmp(argv[i], "--probe") == 0) {
      print_probe();
      exit(0);
    }

    if (strcmp(argv[i], "--version") == 0) {
      printf("%d.%d.%d\n", SDL_MAJOR_VERSION, SDL_MINOR_VERSION, SDL_MICRO_VERSION);
      exit(0);
    }

    if (strcmp(argv[i], "--frame-script") == 0 && i + 1 < argc) {
      frame_script = argv[++i];
    } else if (strcmp(argv[i], "--interaction-script") == 0 && i + 1 < argc) {
      interaction_script = argv[++i];
    } else if (strcmp(argv[i], "--linger-ms") == 0 && i + 1 < argc) {
      app->linger_ms = atoi(argv[++i]);
    }
  }

  if (frame_script == NULL) {
    fprintf(stderr, "usage: desktop_ui_sdl3_host --frame-script <path> [--linger-ms N]\n");
    return SDL_APP_FAILURE;
  }

  if (parse_frame_script(frame_script, &app->frame) != 0) {
    fprintf(stderr, "failed to parse frame script %s\n", frame_script);
    return SDL_APP_FAILURE;
  }

  if (interaction_script != NULL && parse_interaction_script(interaction_script, app) != 0) {
    fprintf(stderr, "failed to parse interaction script %s\n", interaction_script);
    return SDL_APP_FAILURE;
  }

  if (!SDL_Init(SDL_INIT_VIDEO)) {
    fprintf(stderr, "SDL_Init failed: %s\n", SDL_GetError());
    return SDL_APP_FAILURE;
  }

  init_resource_support(app);

  for (int i = 0; i < app->frame.window_count; i++) {
    dui_window *window = &app->frame.windows[i];

    if (!SDL_CreateWindowAndRenderer(window->title, window->width, window->height,
                                     SDL_WINDOW_RESIZABLE | SDL_WINDOW_HIGH_PIXEL_DENSITY,
                                     &window->window, &window->renderer)) {
      fprintf(stderr, "SDL_CreateWindowAndRenderer failed: %s\n", SDL_GetError());
      return SDL_APP_FAILURE;
    }

    SDL_SetRenderLogicalPresentation(window->renderer, window->width, window->height,
                                     SDL_LOGICAL_PRESENTATION_LETTERBOX);
    SDL_SetRenderDrawBlendMode(window->renderer, SDL_BLENDMODE_BLEND);
    SDL_SetWindowPosition(window->window, window->x, window->y);
  }

  app->start_ticks = SDL_GetTicks();
  app->needs_redraw = 1;
  app->shutdown_requested = 0;
  memset(&app->interaction_summary, 0, sizeof(app->interaction_summary));

  return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppEvent(void *appstate, SDL_Event *event) {
  dui_app *app = (dui_app *)appstate;

  if (app == NULL) {
    return SDL_APP_FAILURE;
  }

  switch (event->type) {
  case SDL_EVENT_QUIT:
    return SDL_APP_SUCCESS;

  case SDL_EVENT_WINDOW_CLOSE_REQUESTED:
    app->shutdown_requested = 1;
    return SDL_APP_SUCCESS;

  case SDL_EVENT_WINDOW_EXPOSED:
  case SDL_EVENT_WINDOW_RESIZED:
  case SDL_EVENT_WINDOW_PIXEL_SIZE_CHANGED:
    app->needs_redraw = 1;
    break;

  case SDL_EVENT_WINDOW_FOCUS_GAINED: {
    dui_interaction_event normalized = {0};
    strncpy(normalized.type, "window_activated", sizeof(normalized.type) - 1);
    copy_window_id_for_native_window(&app->frame, event->window.windowID, normalized.window_id,
                                     sizeof(normalized.window_id));

    apply_interaction_event(app, &normalized, 0);
    break;
  }

  case SDL_EVENT_MOUSE_MOTION: {
    dui_interaction_event normalized = {0};
    strncpy(normalized.type, "pointer_hover", sizeof(normalized.type) - 1);
    normalized.x = (int)event->motion.x;
    normalized.y = (int)event->motion.y;
    app->last_pointer_x = normalized.x;
    app->last_pointer_y = normalized.y;
    copy_window_id_for_native_window(&app->frame, event->motion.windowID, normalized.window_id,
                                     sizeof(normalized.window_id));

    apply_interaction_event(app, &normalized, 0);
    break;
  }

  case SDL_EVENT_MOUSE_BUTTON_DOWN: {
    dui_interaction_event normalized = {0};
    strncpy(normalized.type, "pointer_button", sizeof(normalized.type) - 1);
    normalized.x = (int)event->button.x;
    normalized.y = (int)event->button.y;
    app->last_pointer_x = normalized.x;
    app->last_pointer_y = normalized.y;
    strncpy(normalized.button,
            event->button.button == SDL_BUTTON_RIGHT ? "right" : "left",
            sizeof(normalized.button) - 1);
    copy_window_id_for_native_window(&app->frame, event->button.windowID, normalized.window_id,
                                     sizeof(normalized.window_id));

    apply_interaction_event(app, &normalized, 0);
    break;
  }

  case SDL_EVENT_MOUSE_WHEEL: {
    dui_interaction_event normalized = {0};
    strncpy(normalized.type, "wheel_scrolled", sizeof(normalized.type) - 1);
    normalized.x = app->last_pointer_x;
    normalized.y = app->last_pointer_y;
    normalized.delta_x = (int)event->wheel.x;
    normalized.delta_y = (int)event->wheel.y;
    copy_window_id_for_native_window(&app->frame, event->wheel.windowID, normalized.window_id,
                                     sizeof(normalized.window_id));

    apply_interaction_event(app, &normalized, 0);
    break;
  }

  case SDL_EVENT_KEY_DOWN: {
    dui_interaction_event normalized = {0};
    SDL_Keymod mods = SDL_GetModState();
    strncpy(normalized.type, "keyboard_key_down", sizeof(normalized.type) - 1);
    strncpy(normalized.key, SDL_GetKeyName(event->key.key), sizeof(normalized.key) - 1);

    if ((mods & SDL_KMOD_CTRL) != 0) {
      strncpy(normalized.modifiers, "ctrl", sizeof(normalized.modifiers) - 1);
    } else if ((mods & SDL_KMOD_SHIFT) != 0) {
      strncpy(normalized.modifiers, "shift", sizeof(normalized.modifiers) - 1);
    } else if ((mods & SDL_KMOD_ALT) != 0) {
      strncpy(normalized.modifiers, "alt", sizeof(normalized.modifiers) - 1);
    } else if ((mods & SDL_KMOD_GUI) != 0) {
      strncpy(normalized.modifiers, "meta", sizeof(normalized.modifiers) - 1);
    }
    copy_window_id_for_native_window(&app->frame, event->key.windowID, normalized.window_id,
                                     sizeof(normalized.window_id));

    apply_interaction_event(app, &normalized, 0);
    break;
  }

  default:
    break;
  }

  return SDL_APP_CONTINUE;
}

SDL_AppResult SDL_AppIterate(void *appstate) {
  dui_app *app = (dui_app *)appstate;

  if (app == NULL) {
    return SDL_APP_FAILURE;
  }

  if (app->needs_redraw) {
    for (int i = 0; i < app->frame.window_count; i++) {
      render_window(app, &app->frame, i);
    }
    app->needs_redraw = 0;
  }

  if (app->next_scripted_event_index < app->scripted_event_count) {
    apply_interaction_event(app, &app->scripted_events[app->next_scripted_event_index++], 1);
  }

  if (app->shutdown_requested) {
    return SDL_APP_SUCCESS;
  }

  if (app->linger_ms >= 0 && (int)(SDL_GetTicks() - app->start_ticks) >= app->linger_ms) {
    return SDL_APP_SUCCESS;
  }

  return SDL_APP_CONTINUE;
}

void SDL_AppQuit(void *appstate, SDL_AppResult result) {
  dui_app *app = (dui_app *)appstate;
  (void)result;

  if (app != NULL) {
    printf(
        "{\"interaction_summary\":{\"total_events\":%d,\"scripted_events\":%d,"
        "\"live_events\":%d,\"focus_changes\":%d,\"command_activations\":%d,"
        "\"selection_changes\":%d,\"submit_actions\":%d,\"scroll_events\":%d,"
        "\"overlay_transitions\":%d,\"window_activations\":%d,"
        "\"multiwindow_focus_transfers\":%d,\"active_window_id\":\"%s\","
        "\"focused_widget_id\":\"%s\",\"last_command_widget_id\":\"%s\","
        "\"last_command_intent\":\"%s\",\"last_selected_widget_id\":\"%s\","
        "\"last_submit_widget_id\":\"%s\",\"last_scroll_widget_id\":\"%s\"}}\n",
        app->interaction_summary.total_events, app->interaction_summary.scripted_events,
        app->interaction_summary.live_events, app->interaction_summary.focus_changes,
        app->interaction_summary.command_activations, app->interaction_summary.selection_changes,
        app->interaction_summary.submit_actions, app->interaction_summary.scroll_events,
        app->interaction_summary.overlay_transitions, app->interaction_summary.window_activations,
        app->interaction_summary.multiwindow_focus_transfers,
        app->interaction_summary.active_window_id, app->interaction_summary.focused_widget_id,
        app->interaction_summary.last_command_widget_id,
        app->interaction_summary.last_command_intent,
        app->interaction_summary.last_selected_widget_id,
        app->interaction_summary.last_submit_widget_id,
        app->interaction_summary.last_scroll_widget_id);
    destroy_frame_windows(&app->frame);
    destroy_resource_support(app);
    free(app);
  }

  SDL_Quit();
}

static void destroy_frame_windows(dui_frame *frame) {
  for (int i = 0; i < frame->window_count; i++) {
    if (frame->windows[i].renderer != NULL) {
      SDL_DestroyRenderer(frame->windows[i].renderer);
      frame->windows[i].renderer = NULL;
    }

    if (frame->windows[i].window != NULL) {
      SDL_DestroyWindow(frame->windows[i].window);
      frame->windows[i].window = NULL;
    }
  }
}

static int parse_frame_script(const char *path, dui_frame *frame) {
  FILE *file = fopen(path, "r");
  if (file == NULL) {
    return -1;
  }

  char line[MAX_LINE];
  while (fgets(line, sizeof(line), file) != NULL) {
    size_t length = strlen(line);
    if (length > 0 && line[length - 1] == '\n') {
      line[length - 1] = '\0';
    }

    if (strncmp(line, "WINDOW\t", 7) == 0) {
      if (frame->window_count >= MAX_WINDOWS) {
        continue;
      }

      dui_window *window = &frame->windows[frame->window_count++];
      char attrs[20][2][256];
      int count = parse_attrs(line + 7, attrs, 20);

      copy_attr(window->window_id, sizeof(window->window_id), attrs, count, "window_id",
                "window:desktop-ui");
      copy_attr(window->title, sizeof(window->title), attrs, count, "title", "DesktopUi");
      window->x = int_attr(attrs, count, "x", 64);
      window->y = int_attr(attrs, count, "y", 64);
      window->width = int_attr(attrs, count, "width", 1280);
      window->height = int_attr(attrs, count, "height", 800);
      window->window = NULL;
      window->renderer = NULL;
    } else if (strncmp(line, "DRAW\t", 5) == 0) {
      if (frame->draw_count >= MAX_DRAWS) {
        continue;
      }

      dui_draw *draw = &frame->draws[frame->draw_count++];
      char attrs[48][2][256];
      int count = parse_attrs(line + 5, attrs, 48);

      copy_attr(draw->window_id, sizeof(draw->window_id), attrs, count, "window_id",
                "window:desktop-ui");
      copy_attr(draw->widget_id, sizeof(draw->widget_id), attrs, count, "widget_id", "widget");
      copy_attr(draw->draw_kind, sizeof(draw->draw_kind), attrs, count, "draw_kind",
                "container_surface");
      copy_attr(draw->kind, sizeof(draw->kind), attrs, count, "kind", "widget");
      copy_attr(draw->family, sizeof(draw->family), attrs, count, "family", "content");
      copy_attr(draw->bg, sizeof(draw->bg), attrs, count, "bg", "canvas");
      copy_attr(draw->fg, sizeof(draw->fg), attrs, count, "fg", "content");
      copy_attr(draw->border, sizeof(draw->border), attrs, count, "border", "single");
      copy_attr(draw->variant, sizeof(draw->variant), attrs, count, "variant", "default");
      copy_attr(draw->semantic_role, sizeof(draw->semantic_role), attrs, count, "semantic_role",
                "body");
      copy_attr(draw->attrs, sizeof(draw->attrs), attrs, count, "attrs", "");
      copy_attr(draw->content, sizeof(draw->content), attrs, count, "content", "widget");
      copy_attr(draw->image_source, sizeof(draw->image_source), attrs, count, "image_source", "");
      copy_attr(draw->shortcut, sizeof(draw->shortcut), attrs, count, "shortcut", "");
      copy_attr(draw->shortcut_intent, sizeof(draw->shortcut_intent), attrs, count,
                "shortcut_intent", "");
      copy_attr(draw->click_intent, sizeof(draw->click_intent), attrs, count, "click_intent",
                "");
      copy_attr(draw->submit_intent, sizeof(draw->submit_intent), attrs, count, "submit_intent",
                "");
      copy_attr(draw->selection_intent, sizeof(draw->selection_intent), attrs, count,
                "selection_intent", "");
      copy_attr(draw->command_intent, sizeof(draw->command_intent), attrs, count, "command_intent",
                "");
      copy_attr(draw->close_intent, sizeof(draw->close_intent), attrs, count, "close_intent",
                "");
      copy_attr(draw->navigation_intent, sizeof(draw->navigation_intent), attrs, count,
                "navigation_intent", "");
      copy_attr(draw->window_identity, sizeof(draw->window_identity), attrs, count,
                "window_identity", "");
      copy_attr(draw->overlay_role, sizeof(draw->overlay_role), attrs, count, "overlay_role", "");
      copy_attr(draw->selection_mode, sizeof(draw->selection_mode), attrs, count,
                "selection_mode", "");
      draw->x = int_attr(attrs, count, "x", 0);
      draw->y = int_attr(attrs, count, "y", 0);
      draw->width = int_attr(attrs, count, "width", 240);
      draw->height = int_attr(attrs, count, "height", 48);
      draw->clip = int_attr(attrs, count, "clip", 0);
      draw->clip_x = int_attr(attrs, count, "clip_x", draw->x);
      draw->clip_y = int_attr(attrs, count, "clip_y", draw->y);
      draw->clip_width = int_attr(attrs, count, "clip_width", draw->width);
      draw->clip_height = int_attr(attrs, count, "clip_height", draw->height);
      draw->focusable = int_attr(attrs, count, "focusable", 0);
      draw->disabled = int_attr(attrs, count, "disabled", 0);
      draw->focused = int_attr(attrs, count, "focused", 0);
      draw->selected = int_attr(attrs, count, "selected", 0);
      draw->checked = int_attr(attrs, count, "checked", 0);
      draw->active = int_attr(attrs, count, "active", 0);
      draw->open = int_attr(attrs, count, "open", 0);
      draw->current = int_attr(attrs, count, "current", 0);
      draw->loading = int_attr(attrs, count, "loading", 0);
      draw->child_count = int_attr(attrs, count, "child_count", 0);
      draw->item_count = int_attr(attrs, count, "item_count", 0);
      draw->row_count = int_attr(attrs, count, "row_count", 0);
      draw->column_count = int_attr(attrs, count, "column_count", 0);
      draw->series_count = int_attr(attrs, count, "series_count", 0);
      draw->current_index = int_attr(attrs, count, "current_index", -1);
      draw->selected_index = int_attr(attrs, count, "selected_index", -1);
      draw->value = int_attr(attrs, count, "value", 0);
      draw->max_value = int_attr(attrs, count, "max_value", 100);
      draw->content_length = int_attr(attrs, count, "content_length", (int)strlen(draw->content));
    }
  }

  fclose(file);
  return frame->window_count > 0 ? 0 : -1;
}

static int parse_attrs(char *line, char attrs[][2][256], int max_attrs) {
  int count = 0;
  char *token = strtok(line, "\t");

  while (token != NULL && count < max_attrs) {
    char *equals = strchr(token, '=');
    if (equals != NULL) {
      size_t key_len = (size_t)(equals - token);
      if (key_len >= 255) {
        key_len = 255;
      }

      strncpy(attrs[count][0], token, key_len);
      attrs[count][0][key_len] = '\0';
      strncpy(attrs[count][1], equals + 1, 255);
      attrs[count][1][255] = '\0';
      decode_value(attrs[count][1]);
      count++;
    }
    token = strtok(NULL, "\t");
  }

  return count;
}

static void copy_attr(char *dest, size_t dest_size, char attrs[][2][256], int count,
                      const char *key, const char *fallback) {
  for (int i = 0; i < count; i++) {
    if (strcmp(attrs[i][0], key) == 0) {
      strncpy(dest, attrs[i][1], dest_size - 1);
      dest[dest_size - 1] = '\0';
      return;
    }
  }

  strncpy(dest, fallback, dest_size - 1);
  dest[dest_size - 1] = '\0';
}

static int int_attr(char attrs[][2][256], int count, const char *key, int fallback) {
  for (int i = 0; i < count; i++) {
    if (strcmp(attrs[i][0], key) == 0) {
      return atoi(attrs[i][1]);
    }
  }

  return fallback;
}

static int parse_interaction_script(const char *path, dui_app *app) {
  FILE *file = fopen(path, "r");
  if (file == NULL) {
    return -1;
  }

  char line[MAX_LINE];
  while (fgets(line, sizeof(line), file) != NULL) {
    size_t length = strlen(line);
    if (length > 0 && line[length - 1] == '\n') {
      line[length - 1] = '\0';
    }

    if (strncmp(line, "EVENT\t", 6) == 0) {
      if (app->scripted_event_count >= MAX_INTERACTION_EVENTS) {
        continue;
      }

      dui_interaction_event *event = &app->scripted_events[app->scripted_event_count++];
      char attrs[20][2][256];
      int count = parse_attrs(line + 6, attrs, 20);

      copy_attr(event->type, sizeof(event->type), attrs, count, "type", "");
      copy_attr(event->window_id, sizeof(event->window_id), attrs, count, "window_id", "");
      copy_attr(event->widget_id, sizeof(event->widget_id), attrs, count, "widget_id", "");
      copy_attr(event->focus_target, sizeof(event->focus_target), attrs, count, "focus_target", "");
      copy_attr(event->key, sizeof(event->key), attrs, count, "key", "");
      copy_attr(event->modifiers, sizeof(event->modifiers), attrs, count, "modifiers", "");
      copy_attr(event->button, sizeof(event->button), attrs, count, "button", "left");
      copy_attr(event->intent, sizeof(event->intent), attrs, count, "intent", "");
      event->x = int_attr(attrs, count, "x", 0);
      event->y = int_attr(attrs, count, "y", 0);
      event->delta_x = int_attr(attrs, count, "delta_x", 0);
      event->delta_y = int_attr(attrs, count, "delta_y", 0);
    }
  }

  fclose(file);
  return 0;
}

static int is_focusable_draw(const dui_draw *draw) {
  return draw->focusable && !draw->disabled &&
         strcmp(draw->draw_kind, "window_chrome") != 0 &&
         strcmp(draw->draw_kind, "overlay_surface") != 0;
}

static int copy_window_id_for_native_window(dui_frame *frame, SDL_WindowID native_window_id,
                                            char *dest, size_t dest_size) {
  if (dest == NULL || dest_size == 0) {
    return 0;
  }

  dest[0] = '\0';

  for (int index = 0; index < frame->window_count; index++) {
    dui_window *window = &frame->windows[index];

    if (window->window != NULL && SDL_GetWindowID(window->window) == native_window_id) {
      strncpy(dest, window->window_id, dest_size - 1);
      dest[dest_size - 1] = '\0';
      return 1;
    }
  }

  return 0;
}

static int point_in_draw(const dui_draw *draw, int x, int y) {
  return x >= draw->x && x <= (draw->x + draw->width) && y >= draw->y &&
         y <= (draw->y + draw->height);
}

static dui_draw *hit_test_draw(dui_frame *frame, const char *window_id, int x, int y) {
  for (int index = frame->draw_count - 1; index >= 0; index--) {
    dui_draw *draw = &frame->draws[index];

    if (strcmp(draw->window_id, window_id) != 0) {
      continue;
    }

    if ((strcmp(draw->draw_kind, "dialog_surface") == 0 ||
         strcmp(draw->draw_kind, "context_menu_surface") == 0) &&
        !draw->open) {
      continue;
    }

    if (point_in_draw(draw, x, y)) {
      return draw;
    }
  }

  return NULL;
}

static dui_draw *find_draw_by_widget_id(dui_frame *frame, const char *window_id,
                                        const char *widget_id) {
  if (widget_id == NULL || widget_id[0] == '\0') {
    return NULL;
  }

  for (int index = 0; index < frame->draw_count; index++) {
    dui_draw *draw = &frame->draws[index];

    if (strcmp(draw->widget_id, widget_id) != 0) {
      continue;
    }

    if (window_id != NULL && window_id[0] != '\0' && strcmp(draw->window_id, window_id) != 0) {
      continue;
    }

    return draw;
  }

  return NULL;
}

static void focus_draw(dui_app *app, const char *window_id, const char *widget_id) {
  if (window_id == NULL || widget_id == NULL || window_id[0] == '\0' || widget_id[0] == '\0') {
    return;
  }

  dui_draw *focused_draw = find_draw_by_widget_id(&app->frame, window_id, widget_id);
  if (focused_draw == NULL || !is_focusable_draw(focused_draw)) {
    return;
  }

  int changed = strcmp(app->interaction_summary.focused_widget_id, widget_id) != 0;

  for (int index = 0; index < app->frame.draw_count; index++) {
    dui_draw *draw = &app->frame.draws[index];

    if (strcmp(draw->window_id, window_id) == 0) {
      draw->focused = strcmp(draw->widget_id, widget_id) == 0 ? 1 : 0;
    }
  }

  strncpy(app->interaction_summary.focused_widget_id, widget_id,
          sizeof(app->interaction_summary.focused_widget_id) - 1);
  app->interaction_summary.focused_widget_id[sizeof(app->interaction_summary.focused_widget_id) - 1] =
      '\0';
  strncpy(app->interaction_summary.active_window_id, window_id,
          sizeof(app->interaction_summary.active_window_id) - 1);
  app->interaction_summary.active_window_id[sizeof(app->interaction_summary.active_window_id) - 1] =
      '\0';

  if (changed) {
    app->interaction_summary.focus_changes++;
  }
}

static void activate_draw(dui_app *app, dui_draw *draw) {
  if (draw == NULL || draw->disabled) {
    return;
  }

  draw->active = 1;

  if (strcmp(draw->kind, "checkbox") == 0) {
    draw->checked = draw->checked ? 0 : 1;
    app->interaction_summary.selection_changes++;
    strncpy(app->interaction_summary.last_selected_widget_id, draw->widget_id,
            sizeof(app->interaction_summary.last_selected_widget_id) - 1);
    app->interaction_summary
        .last_selected_widget_id[sizeof(app->interaction_summary.last_selected_widget_id) - 1] =
        '\0';
  } else if (strcmp(draw->kind, "text_input") == 0) {
    app->interaction_summary.submit_actions++;
    strncpy(app->interaction_summary.last_submit_widget_id, draw->widget_id,
            sizeof(app->interaction_summary.last_submit_widget_id) - 1);
    app->interaction_summary
        .last_submit_widget_id[sizeof(app->interaction_summary.last_submit_widget_id) - 1] = '\0';
  } else if (strcmp(draw->kind, "button") == 0 || strcmp(draw->kind, "command") == 0 ||
             strcmp(draw->kind, "window_command") == 0 || strcmp(draw->kind, "link") == 0) {
    app->interaction_summary.command_activations++;
    strncpy(app->interaction_summary.last_command_widget_id, draw->widget_id,
            sizeof(app->interaction_summary.last_command_widget_id) - 1);
    app->interaction_summary
        .last_command_widget_id[sizeof(app->interaction_summary.last_command_widget_id) - 1] =
        '\0';

    const char *intent = draw->command_intent[0] != '\0' ? draw->command_intent : draw->click_intent;
    strncpy(app->interaction_summary.last_command_intent, intent,
            sizeof(app->interaction_summary.last_command_intent) - 1);
    app->interaction_summary.last_command_intent[sizeof(app->interaction_summary.last_command_intent) -
                                                 1] = '\0';
  }

  if (draw->submit_intent[0] != '\0') {
    app->interaction_summary.submit_actions++;
    strncpy(app->interaction_summary.last_submit_widget_id, draw->widget_id,
            sizeof(app->interaction_summary.last_submit_widget_id) - 1);
    app->interaction_summary
        .last_submit_widget_id[sizeof(app->interaction_summary.last_submit_widget_id) - 1] = '\0';
  }

  if (draw->close_intent[0] != '\0' || strcmp(draw->widget_id, "dialog-close") == 0 ||
      strcasestr(draw->click_intent, "close") != NULL) {
    close_overlay_draws(app, draw->window_id);
  }
}

static void select_draw_index(dui_app *app, dui_draw *draw, int index) {
  if (draw == NULL) {
    return;
  }

  int max_index = draw->item_count > 0 ? draw->item_count - 1 : draw->row_count - 1;
  if (max_index < 0) {
    max_index = 0;
  }

  if (index < 0) {
    index = 0;
  }

  if (index > max_index) {
    index = max_index;
  }

  draw->selected = 1;
  draw->current = 1;
  draw->selected_index = index;
  draw->current_index = index;
  app->interaction_summary.selection_changes++;
  strncpy(app->interaction_summary.last_selected_widget_id, draw->widget_id,
          sizeof(app->interaction_summary.last_selected_widget_id) - 1);
  app->interaction_summary.last_selected_widget_id[sizeof(app->interaction_summary.last_selected_widget_id) -
                                                   1] = '\0';
}

static void close_overlay_draws(dui_app *app, const char *window_id) {
  int changed = 0;

  for (int index = 0; index < app->frame.draw_count; index++) {
    dui_draw *draw = &app->frame.draws[index];

    if (strcmp(draw->window_id, window_id) == 0 &&
        (strcmp(draw->draw_kind, "dialog_surface") == 0 ||
         strcmp(draw->draw_kind, "context_menu_surface") == 0) &&
        draw->open) {
      draw->open = 0;
      changed = 1;
    }
  }

  if (changed) {
    app->interaction_summary.overlay_transitions++;
  }
}

static void apply_scroll(dui_app *app, dui_draw *draw, int delta_y) {
  if (draw == NULL) {
    return;
  }

  if (draw->item_count > 0 || draw->row_count > 0) {
    select_draw_index(app, draw, draw->current_index + (delta_y < 0 ? 1 : -1));
  } else {
    draw->value = SDL_clamp(draw->value + (delta_y * 8), 0, 100);
  }

  app->interaction_summary.scroll_events++;
  strncpy(app->interaction_summary.last_scroll_widget_id, draw->widget_id,
          sizeof(app->interaction_summary.last_scroll_widget_id) - 1);
  app->interaction_summary.last_scroll_widget_id[sizeof(app->interaction_summary.last_scroll_widget_id) -
                                                 1] = '\0';
}

static void apply_pointer_hover_event(dui_app *app, const dui_interaction_event *event) {
  dui_draw *draw = find_draw_by_widget_id(&app->frame, event->window_id, event->widget_id);
  if (draw == NULL) {
    draw = hit_test_draw(&app->frame, event->window_id, event->x, event->y);
  }

  if (draw != NULL && (draw->item_count > 0 || draw->row_count > 0)) {
    int row_count = draw->item_count > 0 ? draw->item_count : draw->row_count;
    int row_height = SDL_max((draw->height - 16) / SDL_max(row_count, 1), 18);
    int index = (event->y - draw->y - 8) / SDL_max(row_height, 1);
    draw->current_index = SDL_clamp(index, 0, SDL_max(row_count - 1, 0));
  }
}

static void apply_pointer_button_event(dui_app *app, const dui_interaction_event *event) {
  dui_draw *draw = find_draw_by_widget_id(&app->frame, event->window_id, event->widget_id);
  if (draw == NULL) {
    draw = hit_test_draw(&app->frame, event->window_id, event->x, event->y);
  }

  if (draw == NULL) {
    return;
  }

  focus_draw(app, draw->window_id, draw->widget_id);

  if (draw->item_count > 0 || draw->row_count > 0) {
    int row_count = draw->item_count > 0 ? draw->item_count : draw->row_count;
    int row_height = SDL_max((draw->height - 16) / SDL_max(row_count, 1), 18);
    int index = (event->y - draw->y - 8) / SDL_max(row_height, 1);
    select_draw_index(app, draw, index);

    if (strcmp(draw->draw_kind, "context_menu_surface") == 0) {
      close_overlay_draws(app, draw->window_id);
    }

    return;
  }

  if (strcmp(draw->widget_id, "dialog-close") == 0 || strcmp(event->button, "right") == 0) {
    close_overlay_draws(app, draw->window_id);
  }

  activate_draw(app, draw);
}

static void apply_focus_event(dui_app *app, const dui_interaction_event *event) {
  const char *focus_target = event->focus_target[0] != '\0' ? event->focus_target : event->widget_id;
  focus_draw(app, event->window_id, focus_target);
}

static void apply_window_activation_event(dui_app *app, const dui_interaction_event *event) {
  if (event->window_id[0] == '\0') {
    return;
  }

  if (app->interaction_summary.active_window_id[0] != '\0' &&
      strcmp(app->interaction_summary.active_window_id, event->window_id) != 0) {
    app->interaction_summary.multiwindow_focus_transfers++;
  }

  strncpy(app->interaction_summary.active_window_id, event->window_id,
          sizeof(app->interaction_summary.active_window_id) - 1);
  app->interaction_summary
      .active_window_id[sizeof(app->interaction_summary.active_window_id) - 1] = '\0';
  app->interaction_summary.window_activations++;
}

static void apply_keyboard_event(dui_app *app, const dui_interaction_event *event) {
  const char *window_id = event->window_id[0] != '\0' ? event->window_id : app->interaction_summary.active_window_id;
  int focused_index = -1;
  int focusable_indexes[MAX_DRAWS];
  int focusable_count = 0;

  for (int index = 0; index < app->frame.draw_count; index++) {
    dui_draw *draw = &app->frame.draws[index];

    if (strcmp(draw->window_id, window_id) != 0 || !is_focusable_draw(draw)) {
      continue;
    }

    focusable_indexes[focusable_count++] = index;
    if (draw->focused) {
      focused_index = focusable_count - 1;
    }

    if (draw->shortcut[0] != '\0' && strlen(event->key) == 1 &&
        strcasestr(draw->shortcut, event->key) != NULL &&
        ((string_contains_token(event->modifiers, "ctrl") && strcasestr(draw->shortcut, "ctrl") != NULL) ||
         (string_contains_token(event->modifiers, "meta") && strcasestr(draw->shortcut, "cmd") != NULL) ||
         (string_contains_token(event->modifiers, "alt") && strcasestr(draw->shortcut, "alt") != NULL))) {
      focus_draw(app, draw->window_id, draw->widget_id);
      activate_draw(app, draw);
      return;
    }
  }

  if (strcasecmp(event->key, "Tab") == 0 && focusable_count > 0) {
    int next = string_contains_token(event->modifiers, "shift") ? focused_index - 1 : focused_index + 1;
    if (next < 0) {
      next = focusable_count - 1;
    }
    if (next >= focusable_count) {
      next = 0;
    }

    focus_draw(app, window_id, app->frame.draws[focusable_indexes[next]].widget_id);
    return;
  }

  if (strcasecmp(event->key, "Escape") == 0) {
    close_overlay_draws(app, window_id);
    return;
  }

  if (focusable_count == 0 || focused_index < 0) {
    return;
  }

  dui_draw *focused = &app->frame.draws[focusable_indexes[focused_index]];

  if (strcasecmp(event->key, "Return") == 0 || strcasecmp(event->key, "Enter") == 0 ||
      strcasecmp(event->key, "Space") == 0) {
    activate_draw(app, focused);
    return;
  }

  if (strcasecmp(event->key, "Down") == 0 || strcasecmp(event->key, "Up") == 0) {
    int delta = strcasecmp(event->key, "Down") == 0 ? -1 : 1;
    apply_scroll(app, focused, delta);
  }
}

static void apply_wheel_event(dui_app *app, const dui_interaction_event *event) {
  dui_draw *draw = find_draw_by_widget_id(&app->frame, event->window_id, event->widget_id);
  if (draw == NULL) {
    draw = hit_test_draw(&app->frame, event->window_id, event->x, event->y);
  }

  if (draw != NULL) {
    apply_scroll(app, draw, event->delta_y);
  }
}

static void apply_interaction_event(dui_app *app, const dui_interaction_event *event, int scripted) {
  if (event == NULL || event->type[0] == '\0') {
    return;
  }

  app->interaction_summary.total_events++;
  app->needs_redraw = 1;

  if (scripted) {
    app->interaction_summary.scripted_events++;
  } else {
    app->interaction_summary.live_events++;
  }

  if (strcmp(event->type, "focus_changed") == 0) {
    apply_focus_event(app, event);
  } else if (strcmp(event->type, "window_activated") == 0) {
    apply_window_activation_event(app, event);
  } else if (strcmp(event->type, "pointer_hover") == 0) {
    apply_pointer_hover_event(app, event);
  } else if (strcmp(event->type, "pointer_button") == 0) {
    apply_pointer_button_event(app, event);
  } else if (strcmp(event->type, "wheel_scrolled") == 0) {
    apply_wheel_event(app, event);
  } else if (strcmp(event->type, "keyboard_key_down") == 0) {
    apply_keyboard_event(app, event);
  }
}

static dui_color named_color(const char *name, Uint8 alpha) {
  if (name == NULL || strcmp(name, "canvas") == 0) {
    return (dui_color){28, 32, 43, alpha};
  } else if (strcmp(name, "surface") == 0 || strcmp(name, "panel") == 0) {
    return (dui_color){52, 59, 73, alpha};
  } else if (strcmp(name, "content") == 0) {
    return (dui_color){231, 236, 245, alpha};
  } else if (strcmp(name, "muted") == 0) {
    return (dui_color){156, 166, 184, alpha};
  } else if (strcmp(name, "accent") == 0) {
    return (dui_color){78, 138, 250, alpha};
  } else if (strcmp(name, "selection") == 0) {
    return (dui_color){92, 119, 204, alpha};
  } else if (strcmp(name, "focus_ring") == 0) {
    return (dui_color){255, 206, 107, alpha};
  } else if (strcmp(name, "info") == 0) {
    return (dui_color){96, 165, 250, alpha};
  } else if (strcmp(name, "success") == 0) {
    return (dui_color){74, 222, 128, alpha};
  } else if (strcmp(name, "warning") == 0) {
    return (dui_color){245, 158, 11, alpha};
  } else if (strcmp(name, "danger") == 0) {
    return (dui_color){248, 113, 113, alpha};
  }

  return (dui_color){110, 121, 142, alpha};
}

static SDL_Color as_sdl_color(dui_color color) {
  SDL_Color converted = {color.r, color.g, color.b, color.a};
  return converted;
}

static void use_color(SDL_Renderer *renderer, dui_color color) {
  SDL_SetRenderDrawColor(renderer, color.r, color.g, color.b, color.a);
}

static void fill_rect(SDL_Renderer *renderer, SDL_FRect rect, dui_color color) {
  use_color(renderer, color);
  SDL_RenderFillRect(renderer, &rect);
}

static void stroke_rect(SDL_Renderer *renderer, SDL_FRect rect, dui_color color) {
  use_color(renderer, color);
  SDL_RenderRect(renderer, &rect);
}

static void fill_inset_rect(SDL_Renderer *renderer, SDL_FRect rect, float inset, dui_color color) {
  SDL_FRect inner = {rect.x + inset, rect.y + inset, rect.w - inset * 2.0f, rect.h - inset * 2.0f};
  if (inner.w > 0.0f && inner.h > 0.0f) {
    fill_rect(renderer, inner, color);
  }
}

static void draw_text_bands(SDL_Renderer *renderer, SDL_FRect rect, int content_length,
                            dui_color color, int emphasized) {
  int lines = 1;
  float band_height = emphasized ? 8.0f : 6.0f;
  float left = rect.x + 10.0f;
  float top = rect.y + 10.0f;

  if (content_length > 18) {
    lines = 2;
  }

  if (content_length > 48) {
    lines = 3;
  }

  use_color(renderer, color);

  for (int line = 0; line < lines; line++) {
    float width_ratio = 0.72f - (float)line * 0.12f;
    float width = SDL_max(rect.w * width_ratio, 18.0f);
    SDL_FRect band = {left, top + (float)line * (band_height + 6.0f), width, band_height};
    SDL_RenderFillRect(renderer, &band);
  }
}

static int string_contains_token(const char *attrs, const char *token) {
  if (attrs == NULL || token == NULL || attrs[0] == '\0' || token[0] == '\0') {
    return 0;
  }

  char buffer[128];
  strncpy(buffer, attrs, sizeof(buffer) - 1);
  buffer[sizeof(buffer) - 1] = '\0';

  char *part = strtok(buffer, ",");
  while (part != NULL) {
    if (strcmp(part, token) == 0) {
      return 1;
    }

    part = strtok(NULL, ",");
  }

  return 0;
}

static int file_exists(const char *path) {
  if (path == NULL || path[0] == '\0') {
    return 0;
  }

  FILE *file = fopen(path, "rb");
  if (file == NULL) {
    return 0;
  }

  fclose(file);
  return 1;
}

static const char *default_font_path(void) {
  const char *env_path = getenv("DUI_DEFAULT_FONT");

  if (file_exists(env_path)) {
    return env_path;
  }

  static const char *candidates[] = {
      "/System/Library/Fonts/Supplemental/Arial.ttf",
      "/System/Library/Fonts/SFNS.ttf",
      "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
      "/usr/share/fonts/truetype/liberation2/LiberationSans-Regular.ttf",
      "C:/Windows/Fonts/arial.ttf",
      NULL};

  for (int i = 0; candidates[i] != NULL; i++) {
    if (file_exists(candidates[i])) {
      return candidates[i];
    }
  }

  return NULL;
}

#if defined(DUI_HAS_SDL3_TTF)
static int text_style_flags(const dui_draw *draw) {
  int style = TTF_STYLE_NORMAL;

  if (string_contains_token(draw->attrs, "bold") || strcmp(draw->semantic_role, "title") == 0 ||
      strcmp(draw->semantic_role, "window_chrome") == 0 ||
      strcmp(draw->semantic_role, "primary_action") == 0 ||
      strcmp(draw->semantic_role, "status_info") == 0 ||
      strcmp(draw->semantic_role, "status_warning") == 0 ||
      strcmp(draw->semantic_role, "status_danger") == 0) {
    style |= TTF_STYLE_BOLD;
  }

  if (string_contains_token(draw->attrs, "italic")) {
    style |= TTF_STYLE_ITALIC;
  }

  if (string_contains_token(draw->attrs, "underline")) {
    style |= TTF_STYLE_UNDERLINE;
  }

  if (string_contains_token(draw->attrs, "strikethrough")) {
    style |= TTF_STYLE_STRIKETHROUGH;
  }

  return style;
}

static int text_font_size(const dui_draw *draw, int emphasized) {
  if (strcmp(draw->semantic_role, "title") == 0 || string_contains_token(draw->attrs, "uppercase")) {
    return 24;
  }

  if (strcmp(draw->semantic_role, "caption") == 0 || strcmp(draw->semantic_role, "label") == 0) {
    return 13;
  }

  if (strcmp(draw->semantic_role, "window_chrome") == 0) {
    return 15;
  }

  if (emphasized) {
    return 18;
  }

  return 16;
}

static TTF_Font *load_font(dui_app *app, int size, int style) {
  if (!app->resources.text_backend_ready || app->resources.font_path[0] == '\0') {
    return NULL;
  }

  for (int i = 0; i < app->resources.font_count; i++) {
    dui_font_entry *entry = &app->resources.fonts[i];
    if (entry->size == size && entry->style == style && entry->font != NULL) {
      return entry->font;
    }
  }

  if (app->resources.font_count >= MAX_FONTS) {
    return NULL;
  }

  TTF_Font *font = TTF_OpenFont(app->resources.font_path, (float)size);
  if (font == NULL) {
    fprintf(stderr, "desktop_ui SDL3 host: TTF_OpenFont failed for %s: %s\n",
            app->resources.font_path, SDL_GetError());
    return NULL;
  }

  TTF_SetFontStyle(font, style);

  dui_font_entry *entry = &app->resources.fonts[app->resources.font_count++];
  entry->size = size;
  entry->style = style;
  entry->font = font;
  return font;
}

static SDL_Texture *text_texture_for(dui_app *app, SDL_Renderer *renderer, const dui_draw *draw,
                                     dui_color color, int emphasized, int *width, int *height) {
  if (!app->resources.text_backend_ready || draw->content[0] == '\0') {
    return NULL;
  }

  int style = text_style_flags(draw);
  int font_size = text_font_size(draw, emphasized);

  char normalized[512];
  size_t length = strlen(draw->content);
  if (length >= sizeof(normalized)) {
    length = sizeof(normalized) - 1;
  }

  for (size_t index = 0; index < length; index++) {
    char ch = draw->content[index];
    if (string_contains_token(draw->attrs, "uppercase") && ch >= 'a' && ch <= 'z') {
      normalized[index] = (char)(ch - 32);
    } else {
      normalized[index] = ch;
    }
  }
  normalized[length] = '\0';

  char key[768];
  snprintf(key, sizeof(key), "%s|%d|%d|%u|%u|%u|%u", normalized, font_size, style, color.r,
           color.g, color.b, color.a);

  for (int i = 0; i < app->resources.text_cache_count; i++) {
    dui_text_cache_entry *entry = &app->resources.text_cache[i];
    if (strcmp(entry->key, key) == 0 && entry->texture != NULL) {
      *width = entry->width;
      *height = entry->height;
      return entry->texture;
    }
  }

  if (app->resources.text_cache_count >= MAX_TEXT_CACHE) {
    return NULL;
  }

  TTF_Font *font = load_font(app, font_size, style);
  if (font == NULL) {
    return NULL;
  }

  int measured_width = 0;
  int measured_height = 0;
  TTF_GetStringSize(font, normalized, strlen(normalized), &measured_width, &measured_height);

  SDL_Surface *surface =
      TTF_RenderText_Blended(font, normalized, strlen(normalized), as_sdl_color(color));
  if (surface == NULL) {
    return NULL;
  }

  SDL_Texture *texture = SDL_CreateTextureFromSurface(renderer, surface);
  if (texture == NULL) {
    SDL_DestroySurface(surface);
    return NULL;
  }

  dui_text_cache_entry *entry = &app->resources.text_cache[app->resources.text_cache_count++];
  strncpy(entry->key, key, sizeof(entry->key) - 1);
  entry->key[sizeof(entry->key) - 1] = '\0';
  entry->width = measured_width > 0 ? measured_width : surface->w;
  entry->height = measured_height > 0 ? measured_height : surface->h;
  entry->texture = texture;

  *width = entry->width;
  *height = entry->height;

  SDL_DestroySurface(surface);
  return texture;
}
#endif

static void draw_text_content(dui_app *app, SDL_Renderer *renderer, const dui_draw *draw,
                              SDL_FRect rect, dui_color color, int emphasized) {
#if defined(DUI_HAS_SDL3_TTF)
  if (app->resources.text_backend_ready) {
    int texture_width = 0;
    int texture_height = 0;
    SDL_Texture *texture =
        text_texture_for(app, renderer, draw, color, emphasized, &texture_width, &texture_height);

    if (texture != NULL) {
      SDL_FRect target = {rect.x + 8.0f, rect.y + 6.0f, (float)texture_width, (float)texture_height};
      float available_width = SDL_max(rect.w - 16.0f, 8.0f);
      float available_height = SDL_max(rect.h - 12.0f, 8.0f);

      if (target.w > available_width) {
        float ratio = available_width / target.w;
        target.w = available_width;
        target.h = SDL_max(target.h * ratio, 8.0f);
      }

      if (target.h > available_height) {
        float ratio = available_height / target.h;
        target.h = available_height;
        target.w = SDL_max(target.w * ratio, 8.0f);
      }

      SDL_RenderTexture(renderer, texture, NULL, &target);
      return;
    }
  }
#endif

  draw_text_bands(renderer, rect, draw->content_length, color, emphasized);
}

#if defined(DUI_HAS_SDL3_IMAGE)
static SDL_Texture *image_texture_for(dui_app *app, SDL_Renderer *renderer, const char *source,
                                      int *width, int *height) {
  if (!app->resources.image_backend_ready || source == NULL || source[0] == '\0' ||
      !file_exists(source)) {
    return NULL;
  }

  for (int i = 0; i < app->resources.image_cache_count; i++) {
    dui_image_cache_entry *entry = &app->resources.image_cache[i];
    if (strcmp(entry->source, source) == 0 && entry->texture != NULL) {
      *width = entry->width;
      *height = entry->height;
      return entry->texture;
    }
  }

  if (app->resources.image_cache_count >= MAX_IMAGE_CACHE) {
    return NULL;
  }

  SDL_Surface *surface = IMG_Load(source);
  if (surface == NULL) {
    return NULL;
  }

  SDL_Texture *texture = SDL_CreateTextureFromSurface(renderer, surface);
  if (texture == NULL) {
    SDL_DestroySurface(surface);
    return NULL;
  }

  dui_image_cache_entry *entry = &app->resources.image_cache[app->resources.image_cache_count++];
  strncpy(entry->source, source, sizeof(entry->source) - 1);
  entry->source[sizeof(entry->source) - 1] = '\0';
  entry->width = surface->w;
  entry->height = surface->h;
  entry->texture = texture;

  *width = entry->width;
  *height = entry->height;

  SDL_DestroySurface(surface);
  return texture;
}
#endif

static void draw_image_content(dui_app *app, SDL_Renderer *renderer, const dui_draw *draw,
                               SDL_FRect rect) {
#if defined(DUI_HAS_SDL3_IMAGE)
  if (app->resources.image_backend_ready && draw->image_source[0] != '\0') {
    int image_width = 0;
    int image_height = 0;
    SDL_Texture *texture =
        image_texture_for(app, renderer, draw->image_source, &image_width, &image_height);

    if (texture != NULL) {
      SDL_FRect target = {rect.x + 6.0f, rect.y + 6.0f, rect.w - 12.0f, rect.h - 12.0f};
      SDL_RenderTexture(renderer, texture, NULL, &target);
      return;
    }
  }
#endif

  fill_inset_rect(renderer, rect, 8.0f, named_color("accent", 90));
}

static void draw_item_rows(SDL_Renderer *renderer, SDL_FRect rect, int count, int current_index,
                           int selected_index, dui_color base, dui_color highlight) {
  int rows = count > 0 ? count : 3;
  float row_height = SDL_max((rect.h - 16.0f) / (float)rows, 18.0f);

  for (int row = 0; row < rows; row++) {
    SDL_FRect band = {rect.x + 8.0f, rect.y + 8.0f + (float)row * row_height, rect.w - 16.0f,
                      row_height - 6.0f};

    if (row == current_index || row == selected_index) {
      fill_rect(renderer, band, highlight);
    } else {
      fill_rect(renderer, band, base);
    }

    draw_text_bands(renderer, band, 18 + row * 4, named_color("content", 210), 0);
  }
}

static void draw_table_grid(SDL_Renderer *renderer, SDL_FRect rect, int columns, int rows,
                            dui_color stroke, dui_color highlight) {
  int column_count = columns > 0 ? columns : 3;
  int row_count = rows > 0 ? rows : 3;
  float header_height = 28.0f;
  float cell_height = SDL_max((rect.h - header_height - 12.0f) / (float)row_count, 18.0f);
  float cell_width = SDL_max((rect.w - 12.0f) / (float)column_count, 30.0f);

  fill_rect(renderer, (SDL_FRect){rect.x + 6.0f, rect.y + 6.0f, rect.w - 12.0f, header_height},
            highlight);
  draw_text_bands(renderer,
                  (SDL_FRect){rect.x + 12.0f, rect.y + 9.0f, rect.w - 24.0f, header_height - 8.0f},
                  24, named_color("content", 230), 1);

  use_color(renderer, stroke);

  for (int column = 1; column < column_count; column++) {
    float x = rect.x + 6.0f + (float)column * cell_width;
    SDL_RenderLine(renderer, x, rect.y + 6.0f, x, rect.y + rect.h - 6.0f);
  }

  for (int row = 0; row < row_count; row++) {
    float y = rect.y + header_height + 10.0f + (float)row * cell_height;
    SDL_RenderLine(renderer, rect.x + 6.0f, y, rect.x + rect.w - 6.0f, y);
  }
}

static void draw_progress_bar(SDL_Renderer *renderer, SDL_FRect rect, int value, int max_value,
                              dui_color track, dui_color fill) {
  int safe_max = max_value > 0 ? max_value : 100;
  float ratio = SDL_clamp((float)value / (float)safe_max, 0.08f, 1.0f);
  SDL_FRect track_rect = {rect.x + 12.0f, rect.y + rect.h - 22.0f, rect.w - 24.0f, 10.0f};
  SDL_FRect fill_rect_band = {track_rect.x, track_rect.y, track_rect.w * ratio, track_rect.h};

  fill_rect(renderer, track_rect, track);
  fill_rect(renderer, fill_rect_band, fill);
}

static void draw_surface_shell(SDL_Renderer *renderer, SDL_FRect rect, dui_color fill,
                               dui_color stroke, const char *border_kind, int focused,
                               int disabled) {
  Uint8 alpha = disabled ? 120 : fill.a;
  fill.a = alpha;
  stroke.a = disabled ? 180 : stroke.a;

  fill_rect(renderer, rect, fill);

  if (border_kind == NULL || strcmp(border_kind, "none") != 0) {
    if (border_kind != NULL && strcmp(border_kind, "focus_ring") == 0) {
      stroke_rect(renderer, rect, named_color("focus_ring", 255));
    } else {
      if (border_kind != NULL && strcmp(border_kind, "hairline") == 0) {
        stroke.a = 150;
      }

      stroke_rect(renderer, rect, stroke);

      if (border_kind != NULL && strcmp(border_kind, "double") == 0) {
        stroke_rect(renderer,
                    (SDL_FRect){rect.x + 3.0f, rect.y + 3.0f, rect.w - 6.0f, rect.h - 6.0f},
                    stroke);
      }
    }
  }

  if (focused) {
    stroke_rect(renderer, (SDL_FRect){rect.x + 2.0f, rect.y + 2.0f, rect.w - 4.0f, rect.h - 4.0f},
                named_color("focus_ring", 255));
  }
}

static void render_draw_operation(dui_app *app, SDL_Renderer *renderer, const dui_draw *draw) {
  SDL_FRect rect = {(float)draw->x, (float)draw->y, (float)draw->width, (float)draw->height};
  dui_color surface = named_color(draw->bg, draw->disabled ? 120 : 255);
  dui_color stroke = strcmp(draw->border, "focus_ring") == 0 ? named_color("focus_ring", 255)
                                                              : named_color(draw->fg, 210);
  dui_color accent = named_color("accent", 245);
  dui_color selection = named_color("selection", 235);
  dui_color muted = named_color("muted", 190);
  dui_color text = named_color(draw->fg, 230);

  if (strcmp(draw->variant, "quiet") == 0 && strcmp(draw->bg, "surface") == 0) {
    surface = named_color("canvas", draw->disabled ? 110 : 215);
  } else if (strcmp(draw->variant, "filled") == 0 && strcmp(draw->bg, "surface") == 0) {
    surface = named_color("accent", draw->disabled ? 140 : 235);
    text = named_color("surface", 240);
  } else if (strcmp(draw->variant, "elevated") == 0 && strcmp(draw->bg, "surface") == 0) {
    surface = named_color("surface", draw->disabled ? 120 : 250);
    stroke = named_color("content", 220);
  }

  if (strcmp(draw->semantic_role, "status_warning") == 0) {
    text = named_color("warning", 235);
  } else if (strcmp(draw->semantic_role, "status_danger") == 0) {
    text = named_color("danger", 235);
  } else if (strcmp(draw->semantic_role, "status_info") == 0) {
    text = named_color("info", 235);
  } else if (strcmp(draw->semantic_role, "primary_action") == 0 &&
             strcmp(draw->variant, "filled") != 0) {
    text = named_color("accent", 235);
  }

  if (strcmp(draw->draw_kind, "window_chrome") == 0) {
    draw_surface_shell(renderer, rect, named_color("surface", 255), named_color("content", 220),
                       draw->border, draw->focused, 0);
    fill_rect(renderer, (SDL_FRect){rect.x, rect.y, rect.w, 42.0f},
              named_color("canvas", 255));
    fill_rect(renderer, (SDL_FRect){rect.x + 14.0f, rect.y + 14.0f, 12.0f, 12.0f},
              named_color("danger", 220));
    fill_rect(renderer, (SDL_FRect){rect.x + 34.0f, rect.y + 14.0f, 12.0f, 12.0f},
              named_color("warning", 220));
    fill_rect(renderer, (SDL_FRect){rect.x + 54.0f, rect.y + 14.0f, 12.0f, 12.0f},
              named_color("success", 220));
    draw_text_content(app, renderer, draw,
                      (SDL_FRect){rect.x + 88.0f, rect.y + 10.0f, rect.w - 120.0f, 20.0f},
                      named_color("content", 230), 1);
    return;
  }

  if (strcmp(draw->draw_kind, "dialog_surface") == 0 ||
      strcmp(draw->draw_kind, "context_menu_surface") == 0 ||
      strcmp(draw->draw_kind, "container_surface") == 0 ||
      strcmp(draw->draw_kind, "viewport_surface") == 0 ||
      strcmp(draw->draw_kind, "split_pane_surface") == 0 ||
      strcmp(draw->draw_kind, "canvas_surface") == 0) {
    draw_surface_shell(renderer, rect, surface, stroke, draw->border, draw->focused,
                       draw->disabled);

    if (strcmp(draw->draw_kind, "split_pane_surface") == 0) {
      use_color(renderer, named_color("muted", 200));
      SDL_RenderLine(renderer, rect.x + rect.w * 0.6f, rect.y + 8.0f, rect.x + rect.w * 0.6f,
                     rect.y + rect.h - 8.0f);
    } else if (strcmp(draw->draw_kind, "viewport_surface") == 0) {
      stroke_rect(renderer,
                  (SDL_FRect){rect.x + 6.0f, rect.y + 6.0f, rect.w - 12.0f, rect.h - 12.0f},
                  named_color("selection", 210));
    } else if (strcmp(draw->draw_kind, "canvas_surface") == 0) {
      use_color(renderer, named_color("muted", 100));
      for (int line = 1; line < 4; line++) {
        float x = rect.x + (rect.w / 4.0f) * (float)line;
        float y = rect.y + (rect.h / 4.0f) * (float)line;
        SDL_RenderLine(renderer, x, rect.y + 8.0f, x, rect.y + rect.h - 8.0f);
        SDL_RenderLine(renderer, rect.x + 8.0f, y, rect.x + rect.w - 8.0f, y);
      }
    }

    if (strcmp(draw->draw_kind, "dialog_surface") == 0 ||
        strcmp(draw->draw_kind, "context_menu_surface") == 0) {
      draw_text_content(app, renderer, draw,
                        (SDL_FRect){rect.x + 14.0f, rect.y + 12.0f, rect.w - 28.0f, 18.0f},
                        named_color("content", 230), 1);
    }
    return;
  }

  if (strcmp(draw->draw_kind, "overlay_surface") == 0) {
    fill_rect(renderer, rect, named_color("canvas", 120));
    return;
  }

  if (strcmp(draw->draw_kind, "text_block") == 0 || strcmp(draw->draw_kind, "label_block") == 0) {
    if (strcmp(draw->draw_kind, "label_block") == 0) {
      fill_rect(renderer, (SDL_FRect){rect.x, rect.y + 2.0f, rect.w, rect.h - 4.0f},
                named_color("surface", 110));
    }
    draw_text_content(app, renderer, draw, rect, text, strcmp(draw->semantic_role, "title") == 0);
    return;
  }

  if (strcmp(draw->draw_kind, "icon_block") == 0) {
    draw_surface_shell(renderer, rect, named_color("surface", 200), named_color("content", 220),
                       draw->border, 0, 0);
    use_color(renderer, named_color("accent", 240));
    SDL_RenderLine(renderer, rect.x + 10.0f, rect.y + 10.0f, rect.x + rect.w - 10.0f,
                   rect.y + rect.h - 10.0f);
    SDL_RenderLine(renderer, rect.x + rect.w - 10.0f, rect.y + 10.0f, rect.x + 10.0f,
                   rect.y + rect.h - 10.0f);
    return;
  }

  if (strcmp(draw->draw_kind, "image_block") == 0) {
    draw_surface_shell(renderer, rect, named_color("surface", 220), named_color("accent", 210),
                       draw->border, 0, 0);
    draw_image_content(app, renderer, draw, rect);
    return;
  }

  if (strcmp(draw->draw_kind, "button_control") == 0 ||
      strcmp(draw->draw_kind, "command_control") == 0) {
    dui_color fill =
        (draw->active || strcmp(draw->variant, "filled") == 0) ? accent : named_color("surface", 235);
    dui_color border = draw->focused ? named_color("focus_ring", 255) : named_color("content", 220);

    if (draw->current || draw->selected) {
      fill = selection;
    }

    draw_surface_shell(renderer, rect, fill, border, draw->border, draw->focused, draw->disabled);
    draw_text_content(app, renderer, draw,
                      (SDL_FRect){rect.x + 12.0f, rect.y + 8.0f, rect.w - 24.0f, rect.h - 16.0f},
                      named_color("content", 235), 1);
    return;
  }

  if (strcmp(draw->draw_kind, "text_input_control") == 0) {
    draw_surface_shell(renderer, rect, named_color("canvas", 255),
                       draw->focused ? named_color("focus_ring", 255)
                                     : named_color("muted", 210),
                       draw->border, draw->focused, draw->disabled);
    draw_text_content(app, renderer, draw,
                      (SDL_FRect){rect.x + 12.0f, rect.y + 10.0f, rect.w - 30.0f, rect.h - 18.0f},
                      draw->content_length > 0 ? text : muted, 0);

    if (draw->focused) {
      fill_rect(renderer,
                (SDL_FRect){rect.x + rect.w - 16.0f, rect.y + 10.0f, 2.0f, rect.h - 20.0f},
                named_color("focus_ring", 255));
    }
    return;
  }

  if (strcmp(draw->draw_kind, "checkbox_control") == 0) {
    SDL_FRect box = {rect.x + 10.0f, rect.y + 8.0f, 18.0f, 18.0f};
    draw_surface_shell(renderer, rect, named_color("surface", 235), named_color("content", 200),
                       draw->border, draw->focused, draw->disabled);
    stroke_rect(renderer, box, named_color("content", 220));

    if (draw->checked || draw->selected) {
      fill_inset_rect(renderer, box, 4.0f, named_color("accent", 240));
    }

    draw_text_content(app, renderer, draw,
                      (SDL_FRect){rect.x + 38.0f, rect.y + 8.0f, rect.w - 48.0f, rect.h - 16.0f},
                      text, 0);
    return;
  }

  if (strcmp(draw->draw_kind, "numeric_input_control") == 0) {
    draw_surface_shell(renderer, rect, named_color("canvas", 255),
                       draw->focused ? named_color("focus_ring", 255)
                                     : named_color("muted", 210),
                       draw->border, draw->focused, draw->disabled);
    draw_text_content(app, renderer, draw,
                      (SDL_FRect){rect.x + 12.0f, rect.y + 10.0f, rect.w - 48.0f, rect.h - 18.0f},
                      draw->value != 0 ? text : muted, 0);

    SDL_FRect minus_rect = {rect.x + rect.w - 34.0f, rect.y + 8.0f, 12.0f, rect.h - 16.0f};
    SDL_FRect plus_rect = {rect.x + rect.w - 18.0f, rect.y + 8.0f, 14.0f, rect.h - 16.0f};

    fill_rect(renderer, minus_rect, named_color("surface", 235));
    stroke_rect(renderer, minus_rect, named_color("content", 200));
    use_color(renderer, named_color("content", 220));
    SDL_RenderLine(renderer, minus_rect.x + 3.0f, minus_rect.y + minus_rect.h / 2.0f,
                   minus_rect.x + minus_rect.w - 3.0f, minus_rect.y + minus_rect.h / 2.0f);

    fill_rect(renderer, plus_rect, named_color("surface", 235));
    stroke_rect(renderer, plus_rect, named_color("content", 200));
    use_color(renderer, named_color("content", 220));
    SDL_RenderLine(renderer, plus_rect.x + 2.0f, plus_rect.y + plus_rect.h / 2.0f,
                   plus_rect.x + plus_rect.w - 2.0f, plus_rect.y + plus_rect.h / 2.0f);
    SDL_RenderLine(renderer, plus_rect.x + plus_rect.w / 2.0f, plus_rect.y + 3.0f,
                   plus_rect.x + plus_rect.w / 2.0f, plus_rect.y + plus_rect.h - 3.0f);

    if (draw->focused) {
      fill_rect(renderer,
                (SDL_FRect){rect.x + rect.w - 16.0f, rect.y + 10.0f, 2.0f, rect.h - 20.0f},
                named_color("focus_ring", 255));
    }
    return;
  }

  if (strcmp(draw->draw_kind, "slider_control") == 0) {
    draw_surface_shell(renderer, rect, named_color("surface", 235),
                       draw->focused ? named_color("focus_ring", 255) : named_color("content", 200),
                       draw->border, draw->focused, draw->disabled);

    float track_padding = 8.0f;
    SDL_FRect track = {rect.x + track_padding, rect.y + rect.h / 2.0f - 2.0f,
                       rect.w - track_padding * 2.0f, 4.0f};
    fill_rect(renderer, track, named_color("muted", 160));

    int min_val = draw->min_value > 0 ? draw->min_value : 0;
    int max_val = draw->max_value > 0 ? draw->max_value : 100;
    float normalized = (float)(draw->value - min_val) / (float)(max_val - min_val);
    float thumb_x = track.x + normalized * track.w;
    float thumb_y = rect.y + rect.h / 2.0f;
    SDL_FRect thumb = {thumb_x - 8.0f, thumb_y - 8.0f, 16.0f, 16.0f};

    fill_rect(renderer, thumb, draw->focused ? named_color("accent", 240) : named_color("accent", 220));

    if (draw->content_length > 0) {
      draw_text_content(app, renderer, draw,
                        (SDL_FRect){rect.x + 8.0f, rect.y + 6.0f, rect.w - 16.0f, 14.0f},
                        named_color("muted", 220), 0);
    }
    return;
  }

  if (strcmp(draw->draw_kind, "date_input_control") == 0 ||
      strcmp(draw->draw_kind, "time_input_control") == 0) {
    draw_surface_shell(renderer, rect, named_color("canvas", 255),
                       draw->focused ? named_color("focus_ring", 255) : named_color("muted", 210),
                       draw->border, draw->focused, draw->disabled);
    draw_text_content(app, renderer, draw,
                      (SDL_FRect){rect.x + 12.0f, rect.y + 10.0f, rect.w - 48.0f, rect.h - 18.0f},
                      draw->content_length > 0 ? text : muted, 0);

    SDL_FRect picker_rect = {rect.x + rect.w - 32.0f, rect.y + 8.0f, 22.0f, rect.h - 16.0f};
    fill_rect(renderer, picker_rect, named_color("surface", 235));
    use_color(renderer, named_color("content", 200));

    for (int i = 0; i < 3; i++) {
      float dot_x = picker_rect.x + 5.0f + i * 6.0f;
      float dot_y = picker_rect.y + picker_rect.h / 2.0f;
      SDL_RenderLine(renderer, dot_x, dot_y - 2.0f, dot_x, dot_y + 2.0f);
    }

    if (draw->focused) {
      fill_rect(renderer,
                (SDL_FRect){rect.x + rect.w - 16.0f, rect.y + 10.0f, 2.0f, rect.h - 20.0f},
                named_color("focus_ring", 255));
    }
    return;
  }

  if (strcmp(draw->draw_kind, "file_input_control") == 0) {
    draw_surface_shell(renderer, rect, named_color("canvas", 255),
                       draw->focused ? named_color("focus_ring", 255) : named_color("muted", 210),
                       draw->border, draw->focused, draw->disabled);

    draw_text_content(app, renderer, draw,
                      (SDL_FRect){rect.x + 12.0f, rect.y + 10.0f, rect.w - 90.0f, rect.h - 18.0f},
                      draw->content_length > 0 ? text : muted, 0);

    SDL_FRect browse_rect = {rect.x + rect.w - 76.0f, rect.y + 8.0f, 68.0f, rect.h - 16.0f};
    fill_rect(renderer, browse_rect, named_color("surface", 235));
    stroke_rect(renderer, browse_rect, named_color("content", 200));
    use_color(renderer, named_color("content", 230));

    if (draw->focused) {
      fill_rect(renderer,
                (SDL_FRect){rect.x + rect.w - 16.0f, rect.y + 10.0f, 2.0f, rect.h - 20.0f},
                named_color("focus_ring", 255));
    }
    return;
  }

  if (strcmp(draw->draw_kind, "pick_list_surface") == 0) {
    draw_surface_shell(renderer, rect, named_color("canvas", 255),
                       draw->focused ? named_color("focus_ring", 255) : named_color("muted", 210),
                       draw->border, draw->focused, draw->disabled);

    draw_text_content(app, renderer, draw,
                      (SDL_FRect){rect.x + 12.0f, rect.y + 10.0f, rect.w - 48.0f, rect.h - 18.0f},
                      draw->content_length > 0 ? text : muted, 0);

    SDL_FRect dropdown_rect = {rect.x + rect.w - 32.0f, rect.y + 10.0f, 22.0f, rect.h - 20.0f};
    use_color(renderer, draw->focused ? named_color("accent", 220) : named_color("content", 200));

    float cx = dropdown_rect.x + dropdown_rect.w / 2.0f;
    float cy = dropdown_rect.y + dropdown_rect.h / 2.0f;
    SDL_RenderLine(renderer, cx - 4.0f, cy - 2.0f, cx + 4.0f, cy - 2.0f);
    SDL_RenderLine(renderer, cx + 4.0f, cy - 2.0f, cx, cy + 3.0f);
    SDL_RenderLine(renderer, cx, cy + 3.0f, cx - 4.0f, cy - 2.0f);

    if (draw->focused) {
      fill_rect(renderer,
                (SDL_FRect){rect.x + rect.w - 16.0f, rect.y + 10.0f, 2.0f, rect.h - 20.0f},
                named_color("focus_ring", 255));
    }
    return;
  }

  if (strcmp(draw->draw_kind, "radio_group_surface") == 0) {
    draw_surface_shell(renderer, rect, named_color("surface", 235), named_color("content", 200),
                       draw->border, draw->focused, draw->disabled);

    int option_count = draw->item_count > 0 ? draw->item_count : 3;
    float option_height = (rect.h - 16.0f) / (float)option_count;

    for (int i = 0; i < option_count; i++) {
      SDL_FRect radio_rect = {rect.x + 10.0f, rect.y + 8.0f + i * option_height, 18.0f, 18.0f};
      stroke_rect(renderer, radio_rect, named_color("content", 220));

      if (i == draw->selected_index) {
        fill_inset_rect(renderer, radio_rect, 3.0f, named_color("accent", 240));
      }

      SDL_FRect label_rect = {rect.x + 38.0f, rect.y + 8.0f + i * option_height,
                              rect.w - 48.0f, option_height};
      draw_text_bands(renderer, label_rect, 15, named_color("content", 230), 0);
    }
    return;
  }

  if (strcmp(draw->draw_kind, "select_surface") == 0) {
    draw_surface_shell(renderer, rect, named_color("canvas", 255),
                       draw->focused ? named_color("focus_ring", 255) : named_color("muted", 210),
                       draw->border, draw->focused, draw->disabled);
    draw_text_content(app, renderer, draw,
                      (SDL_FRect){rect.x + 12.0f, rect.y + 10.0f, rect.w - 48.0f, rect.h - 18.0f},
                      text, 0);

    SDL_FRect dropdown_rect = {rect.x + rect.w - 32.0f, rect.y + 10.0f, 22.0f, rect.h - 20.0f};
    use_color(renderer, draw->focused ? named_color("accent", 220) : named_color("content", 200));

    float cx = dropdown_rect.x + dropdown_rect.w / 2.0f;
    float cy = dropdown_rect.y + dropdown_rect.h / 2.0f;
    SDL_RenderLine(renderer, cx - 4.0f, cy - 2.0f, cx + 4.0f, cy - 2.0f);
    SDL_RenderLine(renderer, cx + 4.0f, cy - 2.0f, cx, cy + 3.0f);
    SDL_RenderLine(renderer, cx, cy + 3.0f, cx - 4.0f, cy - 2.0f);

    if (draw->focused) {
      fill_rect(renderer,
                (SDL_FRect){rect.x + rect.w - 16.0f, rect.y + 10.0f, 2.0f, rect.h - 20.0f},
                named_color("focus_ring", 255));
    }
    return;
  }

  if (strcmp(draw->draw_kind, "tabs_surface") == 0) {
    draw_surface_shell(renderer, rect, named_color("surface", 210), named_color("content", 180),
                       draw->border, 0, 0);
    draw_item_rows(renderer, (SDL_FRect){rect.x + 6.0f, rect.y + 6.0f, rect.w - 12.0f, rect.h - 12.0f},
                   draw->item_count, draw->current_index, draw->selected_index,
                   named_color("canvas", 180), named_color("accent", 220));
    return;
  }

  if (strcmp(draw->draw_kind, "list_surface") == 0 || strcmp(draw->draw_kind, "menu_surface") == 0) {
    draw_surface_shell(renderer, rect, named_color("surface", 230), named_color("muted", 200),
                       draw->border, 0, 0);
    draw_item_rows(renderer, rect, draw->item_count, draw->current_index, draw->selected_index,
                   named_color("canvas", 160), named_color("selection", 220));
    return;
  }

  if (strcmp(draw->draw_kind, "table_surface") == 0 ||
      strcmp(draw->draw_kind, "process_monitor_surface") == 0) {
    draw_surface_shell(renderer, rect, named_color("surface", 230), named_color("muted", 210),
                       draw->border, 0, 0);
    draw_table_grid(renderer, rect, draw->column_count, draw->row_count,
                    named_color("muted", 150), named_color("accent", 210));
    return;
  }

  if (strcmp(draw->draw_kind, "log_viewer_surface") == 0) {
    draw_surface_shell(renderer, rect, named_color("canvas", 255), named_color("muted", 180),
                       draw->border, 0, 0);
    draw_item_rows(renderer, rect, draw->row_count, -1, -1, named_color("surface", 180),
                   named_color("selection", 220));
    return;
  }

  if (strcmp(draw->draw_kind, "tree_view_surface") == 0) {
    draw_surface_shell(renderer, rect, named_color("surface", 230), named_color("muted", 200),
                       draw->border, 0, 0);

    int item_count = draw->item_count > 0 ? draw->item_count : 3;
    float row_height = 28.0f;
    float indent = 20.0f;

    for (int i = 0; i < item_count && (i * row_height) < (rect.h - 16.0f); i++) {
      int depth = (i % 3);
      float x = rect.x + 8.0f + depth * indent;
      float y = rect.y + 8.0f + i * row_height;

      SDL_FRect expand_rect = {x, y + 4.0f, 12.0f, 12.0f};
      stroke_rect(renderer, expand_rect, named_color("content", 200));
      SDL_RenderLine(renderer, expand_rect.x + 3.0f, expand_rect.y + expand_rect.h / 2.0f,
                     expand_rect.x + expand_rect.w - 3.0f, expand_rect.y + expand_rect.h / 2.0f);

      if (i < 2) {
        SDL_RenderLine(renderer, expand_rect.x + expand_rect.w / 2.0f, expand_rect.y + 4.0f,
                       expand_rect.x + expand_rect.w / 2.0f, expand_rect.y + expand_rect.h - 4.0f);
      }

      SDL_FRect item_rect = {x + 18.0f, y, rect.w - x - rect.x - 24.0f, row_height};
      draw_text_bands(renderer, item_rect, 12, named_color("content", 230), 0);
    }
    return;
  }

  if (strcmp(draw->draw_kind, "stat_block") == 0) {
    draw_surface_shell(renderer, rect, named_color("surface", 235), named_color("muted", 200),
                       draw->border, 0, 0);

    SDL_FRect value_rect = {rect.x + 12.0f, rect.y + 12.0f, rect.w - 24.0f, rect.h * 0.55f};

    if (draw->value > 0 || draw->content_length > 0) {
      use_color(renderer, named_color("accent", 240));
      draw_text_bands(renderer, value_rect, 8, named_color("accent", 240), 1);
    } else {
      draw_text_bands(renderer, value_rect, 8, named_color("muted", 200), 1);
    }

    SDL_FRect label_rect = {rect.x + 12.0f, rect.y + rect.h * 0.62f, rect.w - 24.0f, rect.h * 0.28f};
    draw_text_bands(renderer, label_rect, 12, named_color("muted", 220), 0);

    if (draw->selected || draw->active) {
      int trend = draw->value > 0 ? 1 : (draw->value < 0 ? -1 : 0);
      SDL_FRect trend_rect = {rect.x + rect.w - 28.0f, rect.y + 12.0f, 16.0f, 16.0f};

      if (trend > 0) {
        use_color(renderer, named_color("success", 220));
        SDL_RenderLine(renderer, trend_rect.x + 4.0f, trend_rect.y + trend_rect.h - 4.0f,
                       trend_rect.x + trend_rect.w / 2.0f, trend_rect.y + 4.0f);
        SDL_RenderLine(renderer, trend_rect.x + trend_rect.w / 2.0f, trend_rect.y + 4.0f,
                       trend_rect.x + trend_rect.w - 4.0f, trend_rect.y + trend_rect.h - 4.0f);
      } else if (trend < 0) {
        use_color(renderer, named_color("error", 220));
        SDL_RenderLine(renderer, trend_rect.x + 4.0f, trend_rect.y + 4.0f,
                       trend_rect.x + trend_rect.w / 2.0f, trend_rect.y + trend_rect.h - 4.0f);
        SDL_RenderLine(renderer, trend_rect.x + trend_rect.w / 2.0f, trend_rect.y + trend_rect.h - 4.0f,
                       trend_rect.x + trend_rect.w - 4.0f, trend_rect.y + 4.0f);
      }
    }
    return;
  }

  if (strcmp(draw->draw_kind, "key_value_block") == 0) {
    float mid_x = rect.x + rect.w * 0.45f;
    SDL_FRect key_rect = {rect.x + 12.0f, rect.y + 8.0f, mid_x - rect.x - 16.0f, rect.h - 16.0f};
    SDL_FRect value_rect = {mid_x + 4.0f, rect.y + 8.0f, rect.w - (mid_x - rect.x) - 16.0f, rect.h - 16.0f};

    draw_text_bands(renderer, key_rect, 10, named_color("muted", 220), 0);
    draw_text_bands(renderer, value_rect, 15, named_color("content", 240), 0);

    if (draw->focused) {
      stroke_rect(renderer, (SDL_FRect){rect.x + 4.0f, rect.y + 4.0f, rect.w - 8.0f, rect.h - 8.0f},
                   named_color("focus_ring", 255));
    }
    return;
  }

  if (strcmp(draw->draw_kind, "info_list_block") == 0) {
    draw_surface_shell(renderer, rect, named_color("surface", 235), named_color("muted", 200),
                       draw->border, 0, 0);

    int item_count = draw->item_count > 0 ? draw->item_count : 2;
    float row_height = 24.0f;

    for (int i = 0; i < item_count && (i * row_height) < (rect.h - 8.0f); i++) {
      float y = rect.y + 8.0f + i * row_height;

      SDL_FRect icon_rect = {rect.x + 10.0f, y + 2.0f, 16.0f, 16.0f};
      fill_rect(renderer, icon_rect, named_color("accent", 210));

      SDL_FRect item_rect = {rect.x + 34.0f, y, rect.w - 44.0f, row_height};
      draw_text_bands(renderer, item_rect, 15, named_color("content", 230), 0);
    }
    return;
  }

  if (strcmp(draw->draw_kind, "status_block") == 0) {
    dui_color status_color = named_color("muted", 220);

    if (strcmp(draw->semantic_role, "success") == 0) {
      status_color = named_color("success", 220);
    } else if (strcmp(draw->semantic_role, "warning") == 0) {
      status_color = named_color("warning", 220);
    } else if (strcmp(draw->semantic_role, "error") == 0) {
      status_color = named_color("error", 220);
    } else if (strcmp(draw->semantic_role, "info") == 0) {
      status_color = named_color("info", 220);
    }

    SDL_FRect icon_rect = {rect.x + 8.0f, rect.y + 8.0f, 16.0f, 16.0f};
    fill_rect(renderer, icon_rect, status_color);

    SDL_FRect text_rect = {rect.x + 32.0f, rect.y + 6.0f, rect.w - 40.0f, rect.h - 12.0f};
    draw_text_bands(renderer, text_rect, 15, named_color("content", 230), 0);
    return;
  }

  if (strcmp(draw->draw_kind, "progress_block") == 0) {
    int value = draw->value > 0 ? draw->value : 0;
    int max_value = draw->max_value > 0 ? draw->max_value : 100;

    if (draw->loading || value < 0) {
      int dash_count = 8;
      float dash_width = rect.w / (float)dash_count;

      for (int i = 0; i < dash_count; i++) {
        SDL_FRect dash = {rect.x + i * dash_width, rect.y, dash_width - 4.0f, rect.h};
        fill_rect(renderer, dash, named_color("muted", (160 + (i % 2) * 40) % 255));
      }
    } else {
      float normalized = (float)value / (float)max_value;
      float fill_width = rect.w * normalized;

      fill_rect(renderer, rect, named_color("muted", 160));
      fill_rect(renderer, (SDL_FRect){rect.x, rect.y, fill_width, rect.h}, named_color("accent", 220));
    }
    return;
  }

  if (strcmp(draw->draw_kind, "inline_feedback_surface") == 0) {
    dui_color feedback_color = named_color("surface", 240);

    if (strcmp(draw->semantic_role, "success") == 0) {
      feedback_color = named_color("success", 240);
    } else if (strcmp(draw->semantic_role, "warning") == 0) {
      feedback_color = named_color("warning", 240);
    } else if (strcmp(draw->semantic_role, "error") == 0) {
      feedback_color = named_color("error", 240);
    } else if (strcmp(draw->semantic_role, "info") == 0) {
      feedback_color = named_color("info", 240);
    }

    fill_rect(renderer, rect, feedback_color);
    stroke_rect(renderer, rect, named_color("content", 200));

    if (draw->dismissible) {
      SDL_FRect close_rect = {rect.x + rect.w - 20.0f, rect.y + 6.0f, 14.0f, 14.0f};
      use_color(renderer, named_color("content", 200));
      SDL_RenderLine(renderer, close_rect.x + 3.0f, close_rect.y + 3.0f,
                     close_rect.x + close_rect.w - 3.0f, close_rect.y + close_rect.h - 3.0f);
      SDL_RenderLine(renderer, close_rect.x + close_rect.w - 3.0f, close_rect.y + 3.0f,
                     close_rect.x + 3.0f, close_rect.y + close_rect.h - 3.0f);
    }

    SDL_FRect text_rect = {rect.x + 12.0f, rect.y + 8.0f, rect.w - 44.0f, rect.h - 16.0f};
    draw_text_bands(renderer, text_rect, 20, named_color("content", 240), 0);
    return;
  }

  if (strcmp(draw->draw_kind, "cluster_dashboard_surface") == 0) {
    int count = draw->item_count > 0 ? draw->item_count : 2;
    float card_width = SDL_max((rect.w - 24.0f) / (float)count, 64.0f);
    draw_surface_shell(renderer, rect, named_color("surface", 235), named_color("muted", 200),
                       draw->border, 0, 0);

    for (int index = 0; index < count; index++) {
      SDL_FRect card = {rect.x + 8.0f + (float)index * card_width, rect.y + 18.0f, card_width - 8.0f,
                        rect.h - 28.0f};
      draw_surface_shell(renderer, card, named_color("canvas", 220), named_color("content", 180),
                         "single", 0, 0);
      fill_rect(renderer, (SDL_FRect){card.x + 8.0f, card.y + 8.0f, 12.0f, 12.0f},
                index == 0 ? named_color("success", 230) : named_color("warning", 230));
      draw_text_bands(renderer,
                      (SDL_FRect){card.x + 28.0f, card.y + 6.0f, card.w - 36.0f, card.h - 12.0f},
                      20 + index * 3, named_color("content", 230), 0);
    }
    return;
  }

  if (strcmp(draw->draw_kind, "command_palette_surface") == 0) {
    draw_surface_shell(renderer, rect, named_color("surface", 245), named_color("content", 220),
                       draw->border, 0, 0);
    draw_surface_shell(renderer,
                       (SDL_FRect){rect.x + 10.0f, rect.y + 10.0f, rect.w - 20.0f, 36.0f},
                       named_color("canvas", 255), named_color("muted", 200), "single", 0, 0);
    draw_text_content(app, renderer, draw,
                      (SDL_FRect){rect.x + 18.0f, rect.y + 16.0f, rect.w - 36.0f, 20.0f},
                      text, 0);
    draw_item_rows(renderer,
                   (SDL_FRect){rect.x + 10.0f, rect.y + 54.0f, rect.w - 20.0f, rect.h - 64.0f},
                   draw->item_count, draw->current_index, draw->selected_index,
                   named_color("canvas", 170), named_color("selection", 220));
    return;
  }

  if (strcmp(draw->draw_kind, "gauge_surface") == 0) {
    draw_surface_shell(renderer, rect, named_color("surface", 235), named_color("muted", 200),
                       draw->border, 0, 0);
    draw_text_content(app, renderer, draw,
                      (SDL_FRect){rect.x + 12.0f, rect.y + 10.0f, rect.w - 24.0f, 18.0f},
                      text, 1);
    draw_progress_bar(renderer, rect, draw->value, draw->max_value, named_color("canvas", 190),
                      named_color("accent", 245));
    return;
  }

  if (strcmp(draw->draw_kind, "stream_widget_surface") == 0) {
    draw_surface_shell(renderer, rect, named_color("canvas", 255), named_color("muted", 180),
                       draw->border, 0, 0);

    int row_count = draw->row_count > 0 ? draw->row_count : 10;
    float row_height = 18.0f;
    float visible_rows = (rect.h - 16.0f) / row_height;

    for (int i = 0; i < (int)visible_rows && i < row_count; i++) {
      float y = rect.y + 8.0f + i * row_height;
      SDL_FRect row_rect = {rect.x + 10.0f, y, rect.w - 20.0f, row_height - 2.0f};

      dui_color row_color = named_color("content", 230);
      if (draw->loading || i == (row_count - 1)) {
        row_color = named_color("muted", 200);
      }

      draw_text_bands(renderer, row_rect, 12, row_color, 0);
    }

    if (draw->paused) {
      SDL_FRect pause_indicator = {rect.x + rect.w - 24.0f, rect.y + rect.h - 20.0f, 16.0f, 16.0f};
      fill_rect(renderer, pause_indicator, named_color("warning", 220));
      SDL_RenderLine(renderer, pause_indicator.x + 4.0f, pause_indicator.y + 8.0f,
                     pause_indicator.x + pause_indicator.w - 4.0f, pause_indicator.y + 8.0f);
    }
    return;
  }

  if (strcmp(draw->draw_kind, "supervision_tree_surface") == 0) {
    draw_surface_shell(renderer, rect, named_color("surface", 230), named_color("muted", 200),
                       draw->border, 0, 0);

    int node_count = draw->item_count > 0 ? draw->item_count : 4;
    float row_height = 32.0f;

    for (int i = 0; i < node_count && (i * row_height) < (rect.h - 16.0f); i++) {
      int depth = (i % 4);
      float x = rect.x + 12.0f + depth * 20.0f;
      float y = rect.y + 8.0f + i * row_height;

      dui_color state_color = named_color("success", 220);
      if (i % 4 == 1) state_color = named_color("warning", 220);
      else if (i % 4 == 2) state_color = named_color("error", 220);
      else if (i % 4 == 3) state_color = named_color("muted", 200);

      SDL_FRect state_rect = {x, y + 6.0f, 10.0f, 10.0f};
      fill_rect(renderer, state_rect, state_color);

      SDL_FRect expand_rect = {x + 16.0f, y + 6.0f, 12.0f, 12.0f};
      stroke_rect(renderer, expand_rect, named_color("content", 200));
      SDL_RenderLine(renderer, expand_rect.x + 3.0f, expand_rect.y + expand_rect.h / 2.0f,
                     expand_rect.x + expand_rect.w - 3.0f, expand_rect.y + expand_rect.h / 2.0f);
      if (i < 2) {
        SDL_RenderLine(renderer, expand_rect.x + expand_rect.w / 2.0f, expand_rect.y + 4.0f,
                       expand_rect.x + expand_rect.w / 2.0f, expand_rect.y + expand_rect.h - 4.0f);
      }

      SDL_FRect label_rect = {x + 34.0f, y, rect.w - x - rect.x - 44.0f, row_height};
      draw_text_bands(renderer, label_rect, 16, named_color("content", 230), 0);
    }
    return;
  }

  if (strcmp(draw->draw_kind, "positioned_fragment") == 0) {
    draw_surface_shell(renderer, rect, named_color("accent", 140), named_color("content", 220),
                       draw->border, 0, 0);
    draw_text_content(app, renderer, draw, rect, named_color("content", 235), 0);
    return;
  }

  if (strcmp(draw->draw_kind, "badge_block") == 0) {
    dui_color badge_bg = named_color("accent", 220);
    dui_color badge_fg = named_color("canvas", 255);

    if (strcmp(draw->variant, "success") == 0) {
      badge_bg = named_color("success", 200);
    } else if (strcmp(draw->variant, "warning") == 0) {
      badge_bg = named_color("warning", 220);
    } else if (strcmp(draw->variant, "error") == 0) {
      badge_bg = named_color("error", 200);
    } else if (strcmp(draw->variant, "info") == 0) {
      badge_bg = named_color("info", 210);
    }

    float radius = rect.h * 0.4f;
    fill_rect(renderer, rect, badge_bg);
    draw_text_content(app, renderer, draw, rect, badge_fg, 0);
    return;
  }

  if (strcmp(draw->draw_kind, "hero_block") == 0) {
    fill_rect(renderer, rect, named_color("accent", 240));
    draw_text_content(app, renderer, draw,
                     (SDL_FRect){rect.x + 32.0f, rect.y + 24.0f, rect.w - 64.0f, 48.0f},
                     named_color("canvas", 255), 1);

    if (draw->content_length > 0 && strlen(draw->attrs) > 0) {
      draw_text_content(app, renderer, draw,
                       (SDL_FRect){rect.x + 32.0f, rect.y + 80.0f, rect.w - 64.0f, 24.0f},
                       named_color("canvas", 230), 0);
    }
    return;
  }

  if (strcmp(draw->draw_kind, "link_control") == 0) {
    dui_color link_color = draw->focused ? named_color("accent", 240) : named_color("accent", 220);
    if (draw->active) {
      link_color = named_color("accent", 180);
    }

    draw_text_content(app, renderer, draw, rect, link_color, 0);

    float underline_y = rect.y + rect.h - 4.0f;
    SDL_RenderLine(renderer, rect.x, underline_y, rect.x + rect.w, underline_y);
    return;
  }

  if (strcmp(draw->draw_kind, "separator_line") == 0) {
    dui_color sep_color = named_color("muted", 180);

    if (strcmp(draw->variant, "strong") == 0) {
      sep_color = named_color("content", 200);
    }

    if (draw->width > draw->height) {
      float mid_y = rect.y + rect.h / 2.0f;
      SDL_RenderLine(renderer, rect.x, mid_y, rect.x + rect.w, mid_y);
    } else {
      float mid_x = rect.x + rect.w / 2.0f;
      SDL_RenderLine(renderer, mid_x, rect.y, mid_x, rect.y + rect.h);
    }
    return;
  }

  if (strcmp(draw->draw_kind, "spacer_gap") == 0) {
    return;
  }

  draw_surface_shell(renderer, rect, surface, stroke, draw->border, draw->focused,
                     draw->disabled);
  draw_text_content(app, renderer, draw, rect, text, 0);
}

static void render_window(dui_app *app, dui_frame *frame, int window_index) {
  dui_window *window = &frame->windows[window_index];
  fill_rect(window->renderer, (SDL_FRect){0.0f, 0.0f, (float)window->width, (float)window->height},
            named_color("canvas", 255));

  for (int i = 0; i < frame->draw_count; i++) {
    dui_draw *draw = &frame->draws[i];
    if (strcmp(draw->window_id, window->window_id) != 0) {
      continue;
    }

    if ((strcmp(draw->draw_kind, "dialog_surface") == 0 ||
         strcmp(draw->draw_kind, "context_menu_surface") == 0) &&
        !draw->open) {
      continue;
    }

    if (draw->clip) {
      SDL_Rect clip = {draw->clip_x, draw->clip_y, draw->clip_width, draw->clip_height};
      SDL_SetRenderClipRect(window->renderer, &clip);
    } else {
      SDL_SetRenderClipRect(window->renderer, NULL);
    }

    render_draw_operation(app, window->renderer, draw);
  }

  SDL_SetRenderClipRect(window->renderer, NULL);
  SDL_RenderPresent(window->renderer);
}

static void decode_value(char *value) {
  char *source = value;
  char *target = value;

  while (*source != '\0') {
    if (*source == '%' && source[1] != '\0' && source[2] != '\0') {
      char hex[3] = {source[1], source[2], '\0'};
      *target++ = (char)strtol(hex, NULL, 16);
      source += 3;
    } else if (*source == '+') {
      *target++ = ' ';
      source++;
    } else {
      *target++ = *source++;
    }
  }

  *target = '\0';
}
