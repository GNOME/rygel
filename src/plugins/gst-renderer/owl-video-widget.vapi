[CCode (cprefix = "Owl", lower_case_cprefix = "owl_")]
namespace Owl {
	[CCode (cheader_filename = "owl-video-widget.h")]
	public class VideoWidget : Gtk.Bin, Atk.Implementor, Gtk.Buildable {
		public int get_buffer_percent ();
		public bool get_can_seek ();
		public int get_duration ();
		public bool get_force_aspect_ratio ();
		public bool get_playing ();
		public int get_position ();
		public weak string get_uri ();
		public double get_volume ();
		public VideoWidget ();
		public void set_force_aspect_ratio (bool force_aspect_ratio);
		public void set_playing (bool playing);
		public void set_position (int position);
		public void set_uri (string uri);
		public void set_volume (double volume);
		public int buffer_percent { get; }
		public bool can_seek { get; }
		public int duration { get; }
		public bool force_aspect_ratio { get; set; }
		public bool playing { get; set; }
		public int position { get; set; }
		public string uri { get; set; }
		public double volume { get; set; }
		public virtual signal void eos ();
		public virtual signal void error (GLib.Error error);
		public virtual signal void tag_list_available (Gst.TagList tag_list);
	}
}
