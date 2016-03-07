/*
 * Seahorse
 *
 * Copyright (C) 2008 Stefan Walter
 * Copyright (C) 2011 Collabora Ltd.
 * Copyright (C) 2013 Red Hat Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as
 * published by the Free Software Foundation; either version 2.1 of
 * the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
 * 02111-1307, USA.
 */

namespace Credentials {
	public class Pkcs11PrivateKey : Gck.Object, Gck.ObjectCache {
		public Gck.Attributes attributes {
			owned get {
				return this._attributes;
			}
			set {
				this._attributes = value;
				notify_property ("attributes");
			}
		}

		Gck.Attributes? _attributes;

		public void fill (Gck.Attributes attributes) {
			Gck.Builder builder = new Gck.Builder (Gck.BuilderFlags.NONE);
			if (this._attributes != null)
				builder.add_all (this._attributes);
			builder.set_all (attributes);
			this._attributes = builder.steal ();
			notify_property ("attributes");
		}

		public string get_label () {
			if (this._attributes != null) {
				string label;
				if (this._attributes.find_string (CKA.LABEL, out label))
					return label;
			}
			return _("Unnamed private key");
		}
	}
}
