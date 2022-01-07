namespace HstWbInstaller.ConsoleApp
{
    using System;
    using System.Collections.Generic;
    using Terminal.Gui;

    public class StagingUiController : Window {
        Toplevel top;

        public StagingUiController (DateTime? start, List<string> list)
        {
            top = new Toplevel (Application.Top.Frame);
            top.KeyPress += (e) => {
                // Prevents Ctrl+Q from closing this.
                // Only Ctrl+C is allowed.
                if (e.KeyEvent.Key == (Key.Q | Key.CtrlMask)) {
                    e.Handled = true;
                }
            };

            bool Close ()
            {
                var n = MessageBox.Query (50, 7, "Close Window.", "Are you sure you want to close this window?", "Yes", "No");
                return n == 0;
            }

            var menu = new MenuBar (new MenuBarItem [] {
                new MenuBarItem ("_Stage", new MenuItem [] {
                    new MenuItem ("_Close", "", () => { if (Close()) { Application.RequestStop(); } }, null, null, Key.CtrlMask | Key.C)
                })
            });
            top.Add (menu);

            var statusBar = new StatusBar (new [] {
                new StatusItem(Key.CtrlMask | Key.C, "~^C~ Close", () => { if (Close()) { Application.RequestStop(); } }),
            });
            top.Add (statusBar);

            Title = $"Worker started at {start}.{start:fff}";
            ColorScheme = Colors.Base;

            Add (new ListView (list) {
                X = 0,
                Y = 0,
                Width = Dim.Fill (),
                Height = Dim.Fill ()
            });

            top.Add (this);
        }

        public void Load ()
        {
            Application.Run (top);
        }
    }
}