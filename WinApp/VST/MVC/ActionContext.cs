using System;
using System.Collections.Generic;
using System.Linq;

namespace System
{
    public class ActionContext : Document
    {
        public Action Invoke { get; set; }
        public List<string> Refs => GetArray<List<string>>(nameof(Refs));
        public string Text { get => GetString(nameof(Text)); set => Push(nameof(Text), value); }

        ActionContextCollection _childs;
        public bool HasChild => Childs.Count != 0;

        public ActionContextCollection Childs
        {
            get
            {
                if (_childs == null)
                    _childs = GetArray<ActionContextCollection>(nameof(Childs)) ?? new ActionContextCollection();
                return _childs;
            }
            set => _childs = value;
        }

        public ActionContext Add(ActionContext child)
        {
            Childs.Add(child);
            return this;
        }
        public ActionContext Add(string text, string url) => Add(new ActionContext(text, url));
        public ActionContext Add(string text, string url, Action action) => Add(new ActionContext(text, url, action));
        public ActionContext Add(string text, Action action) => Add(new ActionContext(text, action));

        public ActionContext() { }
        public ActionContext(string text) : this(text, null, null) { }
        public ActionContext(string text, string url) : this(text, url, null) { }
        public ActionContext(string text, Action action) : this(text, null, action) { }

        public ActionContext(string text, string url, Action action)
        {
            Text = text;
            Url = url;
            Invoke = action;
        }
    }

    public class ActionManager : Document
    {
        Document _keys;
        Document _actors;

        private bool HasKey(Document d, string key)
            => d != null && d.Keys != null && key != null && d.Keys.Contains(key);

        private string GetKeyText(string key)
        {
            // lấy text từ bảng "#" trong json; nếu không có thì fallback = key
            if (!HasKey(_keys, key)) return key;
            try
            {
                var o = _keys[key];
                return o?.ToString() ?? key;
            }
            catch
            {
                return key;
            }
        }

        ActionContext createContext(string key, ActionContext a)
        {
            if (a == null) a = new ActionContext();

            if (key != null)
            {
                a.Url = key;

                // nếu Text chưa có thì lấy từ _keys (bảng "#")
                if (string.IsNullOrEmpty(a.Text))
                    a.Text = GetKeyText(key);
            }

            // normalize cho các node con đã có sẵn trong json
            if (a.HasChild)
            {
                foreach (var child in a.Childs)
                    createContext(null, child);
            }

            // expand refs
            var r = a.Refs;
            if (r != null)
            {
                foreach (var s in r)
                {
                    var child = CreateActionContext(s);
                    a.Childs.Add(child);
                }
            }

            return a;
        }

        public ActionManager(Document src)
        {
            Copy(src);

            _keys = GetDocument("#");          // có thể null nếu json không có "#"
            _actors = GetDocument("actors");   // có thể null nếu json không có "actors"

            var gen = new Document();

            if (_actors != null && _actors.Keys != null)
            {
                foreach (var actor in _actors.Keys)
                {
                    var actorDoc = _actors.GetDocument(actor);
                    var dst = new ActionContext();

                    if (actorDoc != null && actorDoc.Keys != null)
                    {
                        foreach (var top in actorDoc.Keys)
                        {
                            var a = actorDoc.GetDocument<ActionContext>(top);
                            dst.Childs.Add(createContext(top, a));
                        }
                    }

                    gen.Add(actor, dst);
                }
            }

            _actors = gen;
        }

        public ActionContext GetTopMenu(string name)
        {
            // default role
            if (string.IsNullOrWhiteSpace(name)) name = "Developer";

            // nếu actors rỗng thì trả menu rỗng
            if (_actors == null || _actors.Keys == null || _actors.Keys.Count == 0)
                return new ActionContext();

            // nếu thiếu key (vd "Staff") thì fallback
            if (!_actors.Keys.Contains(name))
            {
                if (_actors.Keys.Contains("Developer")) name = "Developer";
                else if (_actors.Keys.Contains("Admin")) name = "Admin";
                else name = _actors.Keys.FirstOrDefault();
            }

            // lấy menu an toàn
            try
            {
                var ctx = _actors.GetDocument<ActionContext>(name);
                if (ctx != null) return ctx;
            }
            catch { }

            try
            {
                return _actors[name] as ActionContext ?? new ActionContext();
            }
            catch
            {
                return new ActionContext();
            }
        }

        public ActionContext CreateActionContext(string key)
        {
            return CreateActionContext(key, GetKeyText(key));
        }

        public ActionContext CreateActionContext(string key, string value)
        {
            return new ActionContext(value, key);
        }
    }

    public class ActionContextCollection : List<ActionContext> { }
}
