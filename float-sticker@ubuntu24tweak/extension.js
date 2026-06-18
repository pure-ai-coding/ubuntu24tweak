import St from 'gi://St';
import Clutter from 'gi://Clutter';
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import { Extension } from 'resource:///org/gnome/shell/extensions/extension.js';

let _keybindingId = null;
let _widgets = [];

class StickerWidget {
    constructor(text, x, y) {
        let labelStyle = 'padding: 10px 14px; color: #111111; font-size: 14px;';

        this._actor = new St.Button({
            reactive: true,
            track_hover: true,
            style: `
                background-color: rgba(255, 255, 255, 0.97);
                border: 1px solid rgba(0, 0, 0, 0.35);
                border-radius: 10px;
                box-shadow: 0 6px 28px rgba(0, 0, 0, 0.35);
                min-width: 120px;
                max-width: 480px;
            `,
            x: x,
            y: y,
        });

        this._box = new St.BoxLayout({ vertical: true });
        this._actor.set_child(this._box);

        this._label = new St.Label({ text, style: labelStyle });
        this._box.add_child(this._label);

        this._scale = 1.0;
        this._dragging = false;
        this._dragStartX = 0;
        this._dragStartY = 0;
        this._lastClickTime = 0;
        this._motionId = null;
        this._releaseId = null;
        this._grab = null;

        this._buttonPressId = this._actor.connect('button-press-event',
            this._onButtonPress.bind(this));
        this._scrollId = this._actor.connect('scroll-event',
            this._onScroll.bind(this));

        Main.layoutManager.uiGroup.add_child(this._actor);
    }

    _onButtonPress(actor, event) {
        let button = event.get_button();
        let time = event.get_time();

        if (button === Clutter.BUTTON_PRIMARY) {
            if (time - this._lastClickTime < 300) {
                this.destroy();
                return Clutter.EVENT_STOP;
            }
            this._lastClickTime = time;

            let [x, y] = event.get_coords();
            this._dragging = true;
            this._dragStartX = x - this._actor.x;
            this._dragStartY = y - this._actor.y;

            // 显式抓取指针：拖动期间所有输入直接路由到本 actor，
            // 这样松开时 button-release 一定能在 actor 上收到（接到 stage 上会被
            // St.Button 默认处理吃掉，导致永远释放不了）。
            this._grab = global.stage.grab(this._actor);
            this._motionId = this._actor.connect('motion-event',
                this._onMotion.bind(this));
            this._releaseId = this._actor.connect('button-release-event',
                this._onRelease.bind(this));
            return Clutter.EVENT_STOP;
        }

        if (button === Clutter.BUTTON_SECONDARY) {
            St.Clipboard.get_default().set_text(St.ClipboardType.CLIPBOARD,
                this._label.get_text());
            return Clutter.EVENT_STOP;
        }

        return Clutter.EVENT_PROPAGATE;
    }

    _onMotion() {
        if (!this._dragging) return Clutter.EVENT_PROPAGATE;
        let [x, y] = global.get_pointer();
        this._actor.x = x - this._dragStartX;
        this._actor.y = y - this._dragStartY;
        return Clutter.EVENT_STOP;
    }

    _endDrag() {
        this._dragging = false;
        if (this._motionId) {
            this._actor.disconnect(this._motionId);
            this._motionId = null;
        }
        if (this._releaseId) {
            this._actor.disconnect(this._releaseId);
            this._releaseId = null;
        }
        if (this._grab) {
            this._grab.dismiss();
            this._grab = null;
        }
    }

    _onRelease() {
        this._endDrag();
        return Clutter.EVENT_STOP;
    }

    _onScroll(actor, event) {
        let dir = event.get_scroll_direction();
        if (dir === Clutter.ScrollDirection.UP)
            this._scale = Math.min(3.0, this._scale + 0.1);
        else if (dir === Clutter.ScrollDirection.DOWN)
            this._scale = Math.max(0.3, this._scale - 0.1);
        this._actor.set_scale(this._scale, this._scale);
        return Clutter.EVENT_STOP;
    }

    destroy() {
        this._endDrag();
        if (this._buttonPressId) {
            this._actor.disconnect(this._buttonPressId);
            this._buttonPressId = null;
        }
        if (this._scrollId) {
            this._actor.disconnect(this._scrollId);
            this._scrollId = null;
        }
        this._actor.destroy();
        let i = _widgets.indexOf(this);
        if (i !== -1) _widgets.splice(i, 1);
    }
}

function _pasteToScreen() {
    St.Clipboard.get_default().get_text(St.ClipboardType.CLIPBOARD, (clip, text) => {
        if (!text || text.trim().length === 0) return;
        let m = Main.layoutManager.primaryMonitor;
        let off = _widgets.length * 30;
        _widgets.push(new StickerWidget(text, m.x + 80 + off, m.y + 80 + off));
    });
}

export default class FloatStickerExtension extends Extension {
    enable() {
        _keybindingId = Main.wm.addKeybinding(
            'paste-to-screen',
            this.getSettings('org.gnome.shell.extensions.float-sticker'),
            Meta.KeyBindingFlags.NONE,
            Shell.ActionMode.NORMAL,
            _pasteToScreen
        );
    }

    disable() {
        if (_keybindingId) {
            Main.wm.removeKeybinding('paste-to-screen');
            _keybindingId = null;
        }
        while (_widgets.length)
            _widgets[0].destroy();
    }
}
