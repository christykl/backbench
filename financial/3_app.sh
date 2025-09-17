#!/usr/bin/env bash
#
# Trading App Setup Script for Ubuntu (Accessible GTK edition)
# Creates a desktop-integrated, AT-SPI-aware stock-trading demo
# -----------------------------------------------------------------

set -euo pipefail

APP_NAME="Stock Trading App"
APP_ID="trading-app"
APP_DIR="$HOME/.local/share/$APP_ID"
DESKTOP_FILE="$HOME/.local/share/applications/$APP_ID.desktop"
BIN_DIR="$HOME/.local/bin"
ICON_DIR="$HOME/.local/share/icons"

echo "🔧  Setting up $APP_NAME …"

# -----------------------------------------------------------------
# 1.  Create directories
# -----------------------------------------------------------------
mkdir -p "$APP_DIR" "$BIN_DIR" "$ICON_DIR" "$(dirname "$DESKTOP_FILE")"

# -----------------------------------------------------------------
# 2.  Write the (GTK) application code
# -----------------------------------------------------------------
cat > "$APP_DIR/trading_client.py" << 'PYEOF'
#!/usr/bin/env python3
"""
Accessible Stock-Trading GUI Client (GTK 3)
Tested with: Python ≥ 3.8, python3-gi ≥ 3.36
"""

import gi, threading, time, requests, os, sys, json
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk, Gdk, GLib, Gio, Atk

SERVER_URL   = os.getenv("TRADING_SERVER", "http://localhost:5001")
USERNAME     = os.getenv("TRADING_USER",   "trader1")

class TradingWindow(Gtk.ApplicationWindow):
    def __init__(self, app):
        super().__init__(application=app, title=f"Stock Trading – {USERNAME}")
        self.set_default_size(920, 640)
        self.set_border_width(8)

        # ===== Top-level grid =================================================
        grid = Gtk.Grid(column_spacing=12, row_spacing=12)
        self.add(grid)

        # ----------------------------------------------------------------------
        # Portfolio frame
        # ----------------------------------------------------------------------
        self.cash_lbl  = Gtk.Label(xalign=0);  self.cash_lbl.get_accessible().set_name("Cash balance")
        self.total_lbl = Gtk.Label(xalign=1);  self.total_lbl.get_accessible().set_name("Total portfolio value")

        port_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=16)
        port_box.pack_start(self.cash_lbl,  False, False, 0)
        port_box.pack_end  (self.total_lbl, False, False, 0)

        port_frame = Gtk.Frame(label="Portfolio")
        port_frame.get_accessible().set_name("Portfolio section")
        port_frame.add(port_box)
        grid.attach(port_frame, 0, 0, 2, 1)

        # ----------------------------------------------------------------------
        # Live-prices TreeView
        # ----------------------------------------------------------------------
        self.liststore = Gtk.ListStore(str, str, str, int)  # sym, name, price, holdings
        tree           = Gtk.TreeView(model=self.liststore)
        tree.get_accessible().set_name("Live stock prices")

        # Create columns with proper formatting
        columns = [
            ("Symbol", 0, None),
            ("Name", 1, None),
            ("Price", 2, "price"),
            ("Holdings", 3, None)
        ]

        for title, col_index, format_type in columns:
            renderer = Gtk.CellRendererText()
            column = Gtk.TreeViewColumn(title, renderer, text=col_index)
            
            if format_type == "price":
                renderer.set_property("xalign", 1.0)
            
            tree.append_column(column)

        scrolled = Gtk.ScrolledWindow(); scrolled.set_hexpand(True); scrolled.set_vexpand(True)
        scrolled.add(tree)

        prices_frame = Gtk.Frame(label="Live Stock Prices")
        prices_frame.add(scrolled)
        grid.attach(prices_frame, 0, 1, 2, 1)

        # Double-click selects symbol in combobox
        tree.connect("row-activated", self.on_row_activated)

        # ----------------------------------------------------------------------
        # Trade controls
        # ----------------------------------------------------------------------
        self.symbol_combo = Gtk.ComboBoxText()
        self.symbol_combo.set_entry_text_column(0)
        self.symbol_combo.set_hexpand(False)
        self.symbol_combo.get_accessible().set_name("Stock symbol drop-down")

        self.qty_entry = Gtk.Entry(text="1")
        self.qty_entry.set_width_chars(6)
        self.qty_entry.get_accessible().set_name("Quantity")

        buy_btn  = Gtk.Button(label="BUY");  buy_btn.get_accessible().set_name("Buy button")
        sell_btn = Gtk.Button(label="SELL"); sell_btn.get_accessible().set_name("Sell button")
        buy_btn.get_style_context().add_class("suggested-action")
        sell_btn.get_style_context().add_class("destructive-action")

        buy_btn.connect ("clicked", self.trade_stock, "BUY")
        sell_btn.connect("clicked", self.trade_stock, "SELL")

        hist_btn = Gtk.Button(label="View History")
        hist_btn.connect("clicked", self.show_history)

        trade_box = Gtk.Box(spacing=6)
        for w in (Gtk.Label(label="Stock:"), self.symbol_combo,
                  Gtk.Label(label="Quantity:"), self.qty_entry,
                  buy_btn, sell_btn, hist_btn):
            trade_box.pack_start(w, False, False, 0)

        trade_frame = Gtk.Frame(label="Trade Stocks"); trade_frame.add(trade_box)
        grid.attach(trade_frame, 0, 2, 2, 1)

        # ----------------------------------------------------------------------
        # Status bar
        # ----------------------------------------------------------------------
        self.status = Gtk.Label(xalign=0); self.status.set_margin_top(4)
        grid.attach(self.status, 0, 3, 2, 1)

        # Background thread for polling-loop
        threading.Thread(target=self.poll_loop, daemon=True).start()

    # ======================================================================
    # Networking helpers
    # ======================================================================
    def poll_loop(self):
        while True:
            try:
                stocks = requests.get(f"{SERVER_URL}/api/stocks", timeout=5).json()["stocks"]
                user   = requests.get(f"{SERVER_URL}/api/user/{USERNAME}", timeout=5).json()

                GLib.idle_add(self.refresh_ui, stocks, user, priority=GLib.PRIORITY_DEFAULT)
                time.sleep(2)
            except Exception as e:
                GLib.idle_add(self.status.set_text, f"Connection error: {e}")

    def trade_stock(self, btn, action):  # action ∈ {"BUY","SELL"}
        sym  = self.symbol_combo.get_active_text() or ""
        try: qty = int(self.qty_entry.get_text())
        except ValueError:
            self.alert("Please enter a valid quantity.")
            return

        if not sym or qty <= 0:
            self.alert("Select a stock and positive quantity.")
            return

        try:
            payload = dict(username=USERNAME, symbol=sym, quantity=qty)
            r = requests.post(f"{SERVER_URL}/api/{action.lower()}", json=payload, timeout=5)
            r.raise_for_status()
            self.alert(r.json()["message"], info=True)
        except Exception as e:
            self.alert(f"Trade failed: {e}")

    # ======================================================================
    # UI helpers
    # ======================================================================
    def refresh_ui(self, stocks, user):
        # Portfolio labels
        self.cash_lbl .set_text(f"Cash: $ {user.get('cash',0):,.2f}")
        self.total_lbl.set_text(f"Total Value: $ {user.get('total_value',0):,.2f}")

        # Combo / ListStore
        self.symbol_combo.remove_all()
        self.liststore.clear()
        for sym, info in stocks.items():
            self.symbol_combo.append_text(sym)
            holdings = user.get("stocks", {}).get(sym, 0)
            # Format price as string to display properly
            price_str = f"${info['price']:,.2f}"
            self.liststore.append([sym, info["name"], price_str, holdings])
        if self.symbol_combo.get_active() == -1 and len(stocks):
            self.symbol_combo.set_active(0)
        self.status.set_text("Ready")

    def on_row_activated(self, tree, path, col):
        iter_ = self.liststore.get_iter(path)
        sym   = self.liststore[iter_][0]
        # Find the matching item in combo box
        model = self.symbol_combo.get_model()
        for i, row in enumerate(model):
            if row[0] == sym:
                self.symbol_combo.set_active(i)
                break

    def alert(self, message, info=False):
        md = Gtk.MessageDialog(self, 0,
             Gtk.MessageType.INFO if info else Gtk.MessageType.ERROR,
             Gtk.ButtonsType.OK, message)
        md.run(); md.destroy()

    # ======================================================================
    # History window
    # ======================================================================
    def show_history(self, _btn):
        try:
            txs = requests.get(f"{SERVER_URL}/api/transactions/{USERNAME}", timeout=5).json()["transactions"]
        except Exception as e:
            self.alert(f"Cannot fetch history: {e}")
            return

        win = Gtk.Window(title="Transaction History")
        win.set_default_size(940, 520)

        liststore = Gtk.ListStore(int, str, str, int, str, str, str, str)
        tree      = Gtk.TreeView(model=liststore)
        tree.get_accessible().set_name("Transaction history")

        for i, title in enumerate(("ID","Type","Symbol","Qty","Price","Total","Date/Time","Note")):
            rend = Gtk.CellRendererText()
            col  = Gtk.TreeViewColumn(title, rend, text=i)
            tree.append_column(col)

        for t in txs:
            liststore.append([
                t.get("id",0), t.get("type",""), t.get("symbol",""),
                t.get("quantity",0), 
                f"${t.get('price',0.0):,.2f}",
                f"${t.get('total',0.0):,.2f}",
                t.get("timestamp","")[:19].replace('T',' '), 
                t.get("note","")
            ])

        sw = Gtk.ScrolledWindow(); sw.add(tree)
        win.add(sw); win.show_all()

class TradingApp(Gtk.Application):
    def __init__(self):
        super().__init__(application_id="com.example.TradingApp",
                         flags=Gio.ApplicationFlags.FLAGS_NONE)

    def do_activate(self):
        if not hasattr(self, "win"):
            self.win = TradingWindow(self)
        self.win.show_all()
        self.add_window(self.win)

def main():
    app = TradingApp()
    sys.exit(app.run(None))

if __name__ == "__main__":
    main()
PYEOF
chmod +x "$APP_DIR/trading_client.py"

# -----------------------------------------------------------------
# 3.  Launcher wrapper
# -----------------------------------------------------------------
cat > "$BIN_DIR/trading-app" << EOF
#!/usr/bin/env bash
export GTK_THEME="\${GTK_THEME:-Adwaita}"
exec python3 "$APP_DIR/trading_client.py" "\$@"
EOF
chmod +x "$BIN_DIR/trading-app"

# -----------------------------------------------------------------
# 4.  Icon (same as before)
# -----------------------------------------------------------------
cat > "$ICON_DIR/$APP_ID.svg" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">
  <rect width="64" height="64" fill="#2E7D32" rx="8"/>
  <text x="32" y="24" text-anchor="middle" fill="white" font-family="Arial" font-size="12" font-weight="bold">📈</text>
  <text x="32" y="40" text-anchor="middle" fill="white" font-family="Arial" font-size="8">STOCK</text>
  <text x="32" y="52" text-anchor="middle" fill="white" font-family="Arial" font-size="8">TRADER</text>
</svg>
EOF

# -----------------------------------------------------------------
# 5.  Desktop entry
# -----------------------------------------------------------------
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$APP_NAME
Comment=Fake Stock Trading Application (GTK, a11y)
Exec=$BIN_DIR/trading-app
Icon=$ICON_DIR/$APP_ID.svg
Terminal=false
Categories=Office;Finance;
Keywords=stock;trading;finance;
StartupNotify=true
EOF
chmod +x "$DESKTOP_FILE"

# Optional: copy to ~/Desktop
if [ -d "$HOME/Desktop" ]; then
  cp -f "$DESKTOP_FILE" "$HOME/Desktop/$APP_ID.desktop"
  chmod +x "$HOME/Desktop/$APP_ID.desktop"
  echo "📋  Desktop shortcut: $HOME/Desktop/$APP_ID.desktop"
fi

# -----------------------------------------------------------------
# 6.  Update desktop DB; remind about deps
# -----------------------------------------------------------------
command -v update-desktop-database &>/dev/null \
  && update-desktop-database "$HOME/.local/share/applications" || true

echo -e "\n✅  $APP_NAME installed!"
echo "   • Executable:    $BIN_DIR/trading-app"
echo "   • AppDir:        $APP_DIR"
echo "   • Desktop entry: $DESKTOP_FILE"
echo ""
echo "📦  Dependencies (GTK 3 + requests):"
echo "     sudo apt update && sudo apt install python3-gi gir1.2-gtk-3.0 python3-requests"
echo ""
echo "🚀  Launch from the desktop icon, your launcher, or by running:"
echo "     trading-app"
echo ""

# -----------------------------------------------------------------
# 7.  Done
# -----------------------------------------------------------------
exit 0