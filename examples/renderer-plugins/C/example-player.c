/*
 * Copyright (C) 2012 Intel Corporation
 *
 * This file is part of Rygel.
 *
 * Rygel is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * Rygel is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
 */

#include "example-player.h"

enum  {
  RYGEL_EXAMPLE_PLAYER_DUMMY_PROPERTY,
  RYGEL_EXAMPLE_PLAYER_PLAYBACK_STATE,
  RYGEL_EXAMPLE_PLAYER_URI,
  RYGEL_EXAMPLE_PLAYER_MIME_TYPE,
  RYGEL_EXAMPLE_PLAYER_METADATA,
  RYGEL_EXAMPLE_PLAYER_CONTENT_FEATURES,
  RYGEL_EXAMPLE_PLAYER_VOLUME,
  RYGEL_EXAMPLE_PLAYER_DURATION,
  RYGEL_EXAMPLE_PLAYER_POSITION
};

static void rygel_example_player_rygel_media_player_interface_init (RygelMediaPlayerIface  *iface);

static gboolean
rygel_example_player_real_seek (RygelMediaPlayer *base, gint64 time);

static gchar**
rygel_example_player_real_get_protocols (RygelMediaPlayer *base, int *result_length1);

static gchar**
rygel_example_player_real_get_mime_types (RygelMediaPlayer *base, int *result_length1);

static gchar*
rygel_example_player_real_get_playback_state (RygelMediaPlayer *base);

static void
rygel_example_player_real_set_playback_state (RygelMediaPlayer *base, const gchar *value);

static gchar*
rygel_example_player_real_get_uri (RygelMediaPlayer *base);

static void
rygel_example_player_real_set_uri (RygelMediaPlayer *base, const gchar *value);

static gchar*
rygel_example_player_real_get_mime_type (RygelMediaPlayer *base);

static void
rygel_example_player_real_set_mime_type (RygelMediaPlayer *base, const gchar *value);

static gchar*
rygel_example_player_real_get_metadata (RygelMediaPlayer *base);

static void
rygel_example_player_real_set_metadata (RygelMediaPlayer *base, const gchar *value);

static gchar*
rygel_example_player_real_get_content_features (RygelMediaPlayer *base);

static void
rygel_example_player_real_set_content_features (RygelMediaPlayer *base, const gchar *value);

static gdouble
rygel_example_player_real_get_volume (RygelMediaPlayer *base);

static void
rygel_example_player_real_set_volume (RygelMediaPlayer *base, gdouble value);

static gint64
rygel_example_player_real_get_duration (RygelMediaPlayer *base);

static gint64
rygel_example_player_real_get_position (RygelMediaPlayer *base);

static void
_rygel_example_player_get_property (GObject *object, guint property_id, GValue *value, GParamSpec *pspec);

static void
_rygel_example_player_set_property (GObject *object, guint property_id, const GValue *value, GParamSpec *pspec);

static void
rygel_example_player_finalize (GObject *obj);


G_DEFINE_TYPE_WITH_CODE (RygelExamplePlayer, rygel_example_player, G_TYPE_OBJECT,
                         G_IMPLEMENT_INTERFACE (RYGEL_TYPE_MEDIA_PLAYER,
                                                rygel_example_player_rygel_media_player_interface_init))

struct _RygelExamplePlayerPrivate {
  gchar *_playback_state;
  gchar *_uri;
  gchar *_mime_type;
  gchar *_metadata;
  gchar *_content_features;
  gdouble _volume;
  gint64 _duration;
  gint64 _position;
};

static const gchar* RYGEL_EXAMPLE_PLAYER_PROTOCOLS[] = {"http-get", NULL};
static const gchar* RYGEL_EXAMPLE_PLAYER_MIME_TYPES[] = {"image/jpeg", "image/png", NULL};

RygelExamplePlayer*
rygel_example_player_construct (GType object_type) {
  RygelExamplePlayer *self;

 
  return self;
}


RygelExamplePlayer*
rygel_example_player_new (void) {
  return rygel_example_player_construct (RYGEL_EXAMPLE_TYPE_PLAYER);
}


static void
rygel_example_player_rygel_media_player_interface_init (RygelMediaPlayerIface *iface) {
  iface->seek = (gboolean (*)(RygelMediaPlayer*, gint64)) rygel_example_player_real_seek;
  iface->get_protocols = (gchar **(*)(RygelMediaPlayer*, int*)) rygel_example_player_real_get_protocols;
  iface->get_mime_types = (gchar **(*)(RygelMediaPlayer*, int*)) rygel_example_player_real_get_mime_types;
  iface->get_playback_state = rygel_example_player_real_get_playback_state;
  iface->set_playback_state = rygel_example_player_real_set_playback_state;
  iface->get_uri = rygel_example_player_real_get_uri;
  iface->set_uri = rygel_example_player_real_set_uri;
  iface->get_mime_type = rygel_example_player_real_get_mime_type;
  iface->set_mime_type = rygel_example_player_real_set_mime_type;
  iface->get_metadata = rygel_example_player_real_get_metadata;
  iface->set_metadata = rygel_example_player_real_set_metadata;
  iface->get_content_features = rygel_example_player_real_get_content_features;
  iface->set_content_features = rygel_example_player_real_set_content_features;
  iface->get_volume = rygel_example_player_real_get_volume;
  iface->set_volume = rygel_example_player_real_set_volume;
  iface->get_duration = rygel_example_player_real_get_duration;
  iface->get_position = rygel_example_player_real_get_position;
}

static void
rygel_example_player_class_init (RygelExamplePlayerClass *klass) {
  GObjectClass *gobject_class = G_OBJECT_CLASS (klass);

  g_type_class_add_private (gobject_class, sizeof (RygelExamplePlayerPrivate));

  gobject_class->get_property = _rygel_example_player_get_property;
  gobject_class->set_property = _rygel_example_player_set_property;
  gobject_class->finalize = rygel_example_player_finalize;

  g_object_class_install_property (gobject_class,
    RYGEL_EXAMPLE_PLAYER_PLAYBACK_STATE,
    g_param_spec_string ("playback-state",
      "playback-state",
      "playback-state",
      NULL,
      G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_READABLE | G_PARAM_WRITABLE));

  g_object_class_install_property (gobject_class,
    RYGEL_EXAMPLE_PLAYER_URI,
    g_param_spec_string ("uri",
      "uri",
      "uri",
      NULL,
      G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_READABLE | G_PARAM_WRITABLE));

  g_object_class_install_property (gobject_class,
    RYGEL_EXAMPLE_PLAYER_MIME_TYPE,
    g_param_spec_string ("mime-type",
      "mime-type",
      "mime-type",
      NULL,
      G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_READABLE | G_PARAM_WRITABLE));

  g_object_class_install_property (gobject_class,
    RYGEL_EXAMPLE_PLAYER_METADATA,
    g_param_spec_string ("metadata",
      "metadata",
      "metadata",
      NULL,
      G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_READABLE | G_PARAM_WRITABLE));

  g_object_class_install_property (gobject_class,
    RYGEL_EXAMPLE_PLAYER_CONTENT_FEATURES,
    g_param_spec_string ("content-features",
      "content-features",
      "content-features",
      NULL,
      G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_READABLE | G_PARAM_WRITABLE));

  g_object_class_install_property (gobject_class,
    RYGEL_EXAMPLE_PLAYER_VOLUME,
    g_param_spec_double ("volume",
      "volume",
      "volume",
      -G_MAXDOUBLE,
      G_MAXDOUBLE,
      0.0,
      G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_READABLE | G_PARAM_WRITABLE));

  g_object_class_install_property (gobject_class,
    RYGEL_EXAMPLE_PLAYER_DURATION,
    g_param_spec_int64 ("duration",
      "duration",
      "duration",
      G_MININT64,
      G_MAXINT64,
      0,
      G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_READABLE));

  g_object_class_install_property (gobject_class,
    RYGEL_EXAMPLE_PLAYER_POSITION,
    g_param_spec_int64 ("position",
      "position",
      "position",
      G_MININT64,
      G_MAXINT64,
      0,
      G_PARAM_STATIC_NAME | G_PARAM_STATIC_NICK | G_PARAM_STATIC_BLURB | G_PARAM_READABLE));
}

static void
rygel_example_player_init (RygelExamplePlayer *self) {
  self->priv = RYGEL_EXAMPLE_PLAYER_GET_PRIVATE (self);

  self->priv->_playback_state = g_strdup ("NO_MEDIA_PRESENT");
  self->priv->_uri = NULL;
  self->priv->_mime_type = NULL;
  self->priv->_metadata = NULL;
  self->priv->_content_features = NULL;
  self->priv->_volume = 0;
  self->priv->_duration = 0;
  self->priv->_position = 0;
}


static gboolean
rygel_example_player_real_seek (RygelMediaPlayer *base, gint64 time) {
  /* RygelExamplePlayer *self = RYGEL_EXAMPLE_PLAYER (base); */
  return FALSE;
}

static gchar**
rygel_example_player_real_get_protocols (RygelMediaPlayer *base, int *result_length) {
  /* RygelExamplePlayer *self = RYGEL_EXAMPLE_PLAYER (base); */

  if (result_length) {
    *result_length = g_strv_length (RYGEL_EXAMPLE_PLAYER_PROTOCOLS);
  }

  return g_strdupv (RYGEL_EXAMPLE_PLAYER_PROTOCOLS);
}


static gchar**
rygel_example_player_real_get_mime_types (RygelMediaPlayer *base, int *result_length) {
  /* RygelExamplePlayer *self = RYGEL_EXAMPLE_PLAYER (base); */

  if (result_length) {
    *result_length = g_strv_length (RYGEL_EXAMPLE_PLAYER_MIME_TYPES);
  }

  return g_strdupv (RYGEL_EXAMPLE_PLAYER_MIME_TYPES);
}


static gchar*
rygel_example_player_real_get_playback_state (RygelMediaPlayer *base) {
  RygelExamplePlayer *self = RYGEL_EXAMPLE_PLAYER (base);

  return g_strdup (self->priv->_playback_state);
}


static void
rygel_example_player_real_set_playback_state (RygelMediaPlayer *base, const gchar *value) {
  RygelExamplePlayer *self = RYGEL_EXAMPLE_PLAYER (base);

  g_free (self->priv->_playback_state);
  self->priv->_playback_state = g_strdup (value);

  g_object_notify (G_OBJECT (self), "playback-state");
}


static gchar*
rygel_example_player_real_get_uri (RygelMediaPlayer *base) {
  RygelExamplePlayer *self = RYGEL_EXAMPLE_PLAYER (base);

  return g_strdup (self->priv->_uri);
}


static void
rygel_example_player_real_set_uri (RygelMediaPlayer *base, const gchar *value) {
  RygelExamplePlayer *self = RYGEL_EXAMPLE_PLAYER (base);

  g_free (self->priv->_uri);
  self->priv->_uri = g_strdup (value);

  g_debug ("URI set to %s.", value);
  g_object_notify (G_OBJECT (self), "uri");
}


static gchar*
rygel_example_player_real_get_mime_type (RygelMediaPlayer *base) {
  RygelExamplePlayer *self = RYGEL_EXAMPLE_PLAYER (base);

  return g_strdup (self->priv->_mime_type);
}


static void
rygel_example_player_real_set_mime_type (RygelMediaPlayer *base, const gchar *value) {
  RygelExamplePlayer *self = RYGEL_EXAMPLE_PLAYER (base);

  g_free (self->priv->_mime_type);
  self->priv->_mime_type = g_strdup (value);

  g_object_notify (G_OBJECT (self), "mime-type");
}


static gchar*
rygel_example_player_real_get_metadata (RygelMediaPlayer *base) {
  RygelExamplePlayer *self = RYGEL_EXAMPLE_PLAYER (base);

  return g_strdup (self->priv->_metadata);
}


static void
rygel_example_player_real_set_metadata (RygelMediaPlayer *base, const gchar *value) {
  RygelExamplePlayer *self = RYGEL_EXAMPLE_PLAYER (base);

  g_free (self->priv->_mime_type);
  self->priv->_mime_type = g_strdup (value);

  g_object_notify (G_OBJECT (self), "metadata");
}


static gchar*
rygel_example_player_real_get_content_features (RygelMediaPlayer *base) {
  RygelExamplePlayer *self = RYGEL_EXAMPLE_PLAYER (base);

  return g_strdup (self->priv->_content_features);
}


static void
rygel_example_player_real_set_content_features (RygelMediaPlayer *base, const gchar *value) {
  RygelExamplePlayer *self = RYGEL_EXAMPLE_PLAYER (base);

  g_free (self->priv->_content_features);
  self->priv->_content_features = g_strdup (value);

  g_object_notify (G_OBJECT (self), "content-features");
}


static gdouble
rygel_example_player_real_get_volume (RygelMediaPlayer *base) {
  RygelExamplePlayer *self = RYGEL_EXAMPLE_PLAYER (base);

  return self->priv->_volume;
}


static void
rygel_example_player_real_set_volume (RygelMediaPlayer *base, gdouble value) {
  RygelExamplePlayer *self = RYGEL_EXAMPLE_PLAYER (base);

  self->priv->_volume = value;

  g_debug ("volume set to %f.", value);
  g_object_notify (G_OBJECT (self), "volume");
}


static gint64
rygel_example_player_real_get_duration (RygelMediaPlayer *base) {
  RygelExamplePlayer *self = RYGEL_EXAMPLE_PLAYER (base);

  return self->priv->_duration;
}


static gint64
rygel_example_player_real_get_position (RygelMediaPlayer *base) {
  RygelExamplePlayer *self = RYGEL_EXAMPLE_PLAYER (base);

  return self->priv->_position;
}

static void
_rygel_example_player_get_property (GObject *object, guint property_id, GValue *value, GParamSpec *pspec) {
  RygelMediaPlayer *base = RYGEL_MEDIA_PLAYER (object);

  switch (property_id) {
    case RYGEL_EXAMPLE_PLAYER_PLAYBACK_STATE:
      g_value_take_string (value, rygel_media_player_get_playback_state (base));
      break;
    case RYGEL_EXAMPLE_PLAYER_URI:
      g_value_take_string (value, rygel_media_player_get_uri (base));
      break;
    case RYGEL_EXAMPLE_PLAYER_MIME_TYPE:
      g_value_take_string (value, rygel_media_player_get_mime_type (base));
      break;
    case RYGEL_EXAMPLE_PLAYER_METADATA:
      g_value_take_string (value, rygel_media_player_get_metadata (base));
      break;
    case RYGEL_EXAMPLE_PLAYER_CONTENT_FEATURES:
      g_value_take_string (value, rygel_media_player_get_content_features (base));
      break;
    case RYGEL_EXAMPLE_PLAYER_VOLUME:
      g_value_set_double (value, rygel_media_player_get_volume (base));
      break;
    case RYGEL_EXAMPLE_PLAYER_DURATION:
      g_value_set_int64 (value, rygel_media_player_get_duration (base));
      break;
    case RYGEL_EXAMPLE_PLAYER_POSITION:
      g_value_set_int64 (value, rygel_media_player_get_position (base));
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
  }
}


static void
_rygel_example_player_set_property (GObject *object, guint property_id, const GValue *value, GParamSpec *pspec) {
  RygelMediaPlayer *base = RYGEL_MEDIA_PLAYER (object);

  switch (property_id) {
    case RYGEL_EXAMPLE_PLAYER_PLAYBACK_STATE:
      rygel_media_player_set_playback_state (base, g_value_get_string (value));
      break;
    case RYGEL_EXAMPLE_PLAYER_URI:
      rygel_media_player_set_uri (base, g_value_get_string (value));
      break;
    case RYGEL_EXAMPLE_PLAYER_MIME_TYPE:
      rygel_media_player_set_mime_type (base, g_value_get_string (value));
      break;
    case RYGEL_EXAMPLE_PLAYER_METADATA:
      rygel_media_player_set_metadata (base, g_value_get_string (value));
      break;
    case RYGEL_EXAMPLE_PLAYER_CONTENT_FEATURES:
      rygel_media_player_set_content_features (base, g_value_get_string (value));
      break;
    case RYGEL_EXAMPLE_PLAYER_VOLUME:
      rygel_media_player_set_volume (base, g_value_get_double (value));
      break;
    default:
      G_OBJECT_WARN_INVALID_PROPERTY_ID (object, property_id, pspec);
      break;
  }
}

static void
rygel_example_player_finalize (GObject *obj) {
  RygelExamplePlayer *self = RYGEL_EXAMPLE_PLAYER (obj);

  g_free (self->priv->_playback_state);
  g_free (self->priv->_uri);
  g_free (self->priv->_mime_type);
  g_free (self->priv->_metadata);
  g_free (self->priv->_content_features);

  G_OBJECT_CLASS (rygel_example_player_parent_class)->finalize (obj);
}


