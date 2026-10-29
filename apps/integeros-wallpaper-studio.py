#!/usr/bin/env python3
"""IntegerOS Black Hole Wallpaper Studio — GUI MP4 wallpaper creator."""
from __future__ import annotations

import os
import shutil
import subprocess
import tempfile
import threading
import tkinter as tk
from tkinter import colorchooser, filedialog, messagebox, ttk
from pathlib import Path

APP_NAME = "IntegerOS Black Hole Wallpaper Studio"


def ffmpeg_escape(value: str) -> str:
    """Escape text for FFmpeg drawtext inside a filtergraph."""
    return value.replace("\\", "\\\\").replace(":", "\\:").replace("'", "\\'").replace("%", "\\%")


class WallpaperStudio(tk.Tk):
    def __init__(self) -> None:
        super().__init__()
        self.title(APP_NAME)
        self.geometry("780x760")
        self.minsize(680, 650)
        self.configure(padx=14, pady=12)
        self.video = tk.StringVar()
        self.neg = tk.StringVar()
        self.logo = tk.StringVar()
        self.output = tk.StringVar(value=str(Path.home() / "Videos" / "InnyGrOS-BlackHole-TeamBlacklight.mp4"))
        self.tbl_text = tk.StringVar(value="Team Blacklight")
        self.corp_text = tk.StringVar(value="Innygr Corp")
        self.tbl_color = "#00E5FF"
        self.corp_color = "#B388FF"
        self.font = tk.StringVar(value="DejaVu Sans Mono")
        self.font_size = tk.IntVar(value=30)
        self.duration = tk.IntVar(value=30)
        self.logo_size = tk.IntVar(value=96)
        self.neg_size = tk.IntVar(value=150)
        self.bottom_margin = tk.IntVar(value=110)
        self.threads = tk.IntVar(value=2)
        self.preset = tk.StringVar(value="ultrafast")
        self.status = tk.StringVar(value="Choose your video and original branding assets to begin.")
        self._build_ui()

    def _build_ui(self) -> None:
        ttk.Label(self, text="IntegerOS Wallpaper Studio", font=("Sans", 18, "bold")).pack(anchor="w")
        ttk.Label(self, text="Create a branded MP4 wallpaper with adjustable layout, typography, and rendering settings.").pack(anchor="w", pady=(2, 12))

        files = ttk.LabelFrame(self, text="Media and output", padding=10)
        files.pack(fill="x", pady=4)
        self._file_row(files, "Background video", self.video, self._pick_video, 0)
        self._file_row(files, "NegInny image", self.neg, self._pick_neg, 1)
        self._file_row(files, "Team Blacklight logo", self.logo, self._pick_logo, 2)
        self._file_row(files, "Save MP4 as", self.output, self._pick_output, 3)

        branding = ttk.LabelFrame(self, text="Text and appearance", padding=10)
        branding.pack(fill="x", pady=4)
        branding.columnconfigure(1, weight=1)
        ttk.Label(branding, text="Team Blacklight text").grid(row=0, column=0, sticky="w", padx=(0, 8), pady=4)
        ttk.Entry(branding, textvariable=self.tbl_text).grid(row=0, column=1, sticky="ew", pady=4)
        ttk.Button(branding, text=f"Color: {self.tbl_color}", command=self._pick_tbl_color).grid(row=0, column=2, padx=(8, 0))
        ttk.Label(branding, text="Innygr Corp text").grid(row=1, column=0, sticky="w", padx=(0, 8), pady=4)
        ttk.Entry(branding, textvariable=self.corp_text).grid(row=1, column=1, sticky="ew", pady=4)
        ttk.Button(branding, text=f"Color: {self.corp_color}", command=self._pick_corp_color).grid(row=1, column=2, padx=(8, 0))

        controls = ttk.Frame(branding)
        controls.grid(row=2, column=0, columnspan=3, sticky="ew", pady=(8, 0))
        ttk.Label(controls, text="Font").pack(side="left")
        ttk.Combobox(controls, textvariable=self.font, values=("DejaVu Sans Mono", "DejaVu Sans", "Liberation Sans", "Liberation Mono", "Serif", "Sans"), width=20, state="readonly").pack(side="left", padx=(5, 14))
        ttk.Label(controls, text="Text size").pack(side="left")
        ttk.Spinbox(controls, from_=16, to=72, textvariable=self.font_size, width=5).pack(side="left", padx=5)
        ttk.Label(controls, text="Bottom margin").pack(side="left")
        ttk.Spinbox(controls, from_=50, to=300, increment=10, textvariable=self.bottom_margin, width=5).pack(side="left", padx=5)

        render = ttk.LabelFrame(self, text="Rendering and layout", padding=10)
        render.pack(fill="x", pady=4)
        row1 = ttk.Frame(render)
        row1.pack(fill="x", pady=3)
        ttk.Label(row1, text="Duration (seconds)").pack(side="left")
        ttk.Spinbox(row1, from_=5, to=300, textvariable=self.duration, width=6).pack(side="left", padx=(5, 16))
        ttk.Label(row1, text="NegInny size").pack(side="left")
        ttk.Spinbox(row1, from_=64, to=400, increment=16, textvariable=self.neg_size, width=6).pack(side="left", padx=(5, 16))
        ttk.Label(row1, text="TBL logo size").pack(side="left")
        ttk.Spinbox(row1, from_=48, to=300, increment=16, textvariable=self.logo_size, width=6).pack(side="left", padx=5)
        row2 = ttk.Frame(render)
        row2.pack(fill="x", pady=3)
        ttk.Label(row2, text="Encoder preset").pack(side="left")
        ttk.Combobox(row2, textvariable=self.preset, values=("ultrafast", "superfast", "veryfast", "faster", "fast", "medium"), width=12, state="readonly").pack(side="left", padx=(5, 16))
        ttk.Label(row2, text="CPU threads").pack(side="left")
        ttk.Spinbox(row2, from_=1, to=8, textvariable=self.threads, width=5).pack(side="left", padx=5)
        ttk.Label(render, text="Layout: Team Blacklight text → logo (left); NegInny → Innygr Corp text (right).").pack(anchor="w", pady=(5, 0))

        bottom = ttk.Frame(self)
        bottom.pack(fill="x", pady=(12, 0))
        self.render_button = ttk.Button(bottom, text="Create wallpaper", command=self._start_render)
        self.render_button.pack(side="left")
        ttk.Label(bottom, textvariable=self.status, wraplength=520).pack(side="left", padx=12, fill="x", expand=True)
        ttk.Label(self, text="Tip: ultrafast + 1–2 threads reduces CPU pressure; rendering may take longer with fewer threads.", wraplength=720).pack(anchor="w", pady=(10, 0))

    def _file_row(self, parent, label, variable, command, row):
        ttk.Label(parent, text=label).grid(row=row, column=0, sticky="w", padx=(0, 8), pady=4)
        ttk.Entry(parent, textvariable=variable).grid(row=row, column=1, sticky="ew", pady=4)
        ttk.Button(parent, text="Browse…", command=command).grid(row=row, column=2, padx=(8, 0), pady=4)
        parent.columnconfigure(1, weight=1)

    def _pick_video(self):
        p = filedialog.askopenfilename(title="Choose background video", filetypes=[("Video files", "*.mp4 *.mkv *.webm *.mov *.avi"), ("All files", "*")])
        if p: self.video.set(p)

    def _pick_neg(self):
        p = filedialog.askopenfilename(title="Choose NegInny image", filetypes=[("Images", "*.png *.webp *.jpg *.jpeg"), ("All files", "*")])
        if p: self.neg.set(p)

    def _pick_logo(self):
        p = filedialog.askopenfilename(title="Choose Team Blacklight logo", filetypes=[("Logo images", "*.ico *.png *.webp *.jpg *.jpeg"), ("All files", "*")])
        if p: self.logo.set(p)

    def _pick_output(self):
        p = filedialog.asksaveasfilename(title="Save wallpaper", defaultextension=".mp4", initialfile=Path(self.output.get()).name, initialdir=str(Path(self.output.get()).expanduser().parent), filetypes=[("MP4 video", "*.mp4")])
        if p: self.output.set(p)

    def _pick_tbl_color(self):
        c = colorchooser.askcolor(self.tbl_color, title="Team Blacklight text color")
        if c and c[1]:
            self.tbl_color = c[1]
            self._refresh_color_buttons()

    def _pick_corp_color(self):
        c = colorchooser.askcolor(self.corp_color, title="Innygr Corp text color")
        if c and c[1]:
            self.corp_color = c[1]
            self._refresh_color_buttons()

    def _refresh_color_buttons(self):
        # Update the visible color selectors without rebuilding the form.
        for child in self.winfo_children():
            self._update_color_buttons(child)

    def _update_color_buttons(self, widget):
        if isinstance(widget, ttk.Button):
            if str(widget.cget("text")).startswith("Color:"):
                # The two color buttons are ordered Team Blacklight then Innygr Corp.
                buttons = [w for w in self._all_widgets(self) if isinstance(w, ttk.Button) and str(w.cget("text")).startswith("Color:")]
                if len(buttons) >= 2:
                    buttons[0].configure(text=f"Color: {self.tbl_color}")
                    buttons[1].configure(text=f"Color: {self.corp_color}")
                return
        for child in widget.winfo_children():
            self._update_color_buttons(child)

    def _all_widgets(self, widget):
        for child in widget.winfo_children():
            yield child
            yield from self._all_widgets(child)

    def _start_render(self):
        required = (("background video", self.video.get()), ("NegInny image", self.neg.get()), ("Team Blacklight logo", self.logo.get()))
        for label, path in required:
            if not path or not Path(path).is_file():
                messagebox.showerror(APP_NAME, f"Please choose a valid {label}.")
                return
        if not shutil.which("ffmpeg"):
            messagebox.showerror(APP_NAME, "FFmpeg is required. Install it with: sudo apt install ffmpeg")
            return
        if self.logo.get().lower().endswith(".ico") and not shutil.which("magick"):
            messagebox.showerror(APP_NAME, "ImageMagick is required to convert the selected ICO logo. Install it with: sudo apt install imagemagick")
            return
        out = Path(self.output.get()).expanduser()
        if out.suffix.lower() != ".mp4":
            out = out.with_suffix(".mp4")
            self.output.set(str(out))
        if out.exists() and not messagebox.askyesno(APP_NAME, f"Replace existing file?\n{out}"):
            return
        try:
            if int(self.duration.get()) < 1 or int(self.font_size.get()) < 1:
                raise ValueError
        except (ValueError, tk.TclError):
            messagebox.showerror(APP_NAME, "Duration and font size must be positive numbers.")
            return
        self.render_button.configure(state="disabled")
        self.status.set("Rendering… the application may take a few minutes.")
        threading.Thread(target=self._render_worker, args=(out,), daemon=True).start()

    def _render_worker(self, out: Path):
        try:
            out.parent.mkdir(parents=True, exist_ok=True)
            with tempfile.TemporaryDirectory(prefix="integeros-wallpaper-") as td:
                logo_path = self.logo.get()
                if logo_path.lower().endswith(".ico"):
                    converted = str(Path(td) / "team-blacklight.png")
                    subprocess.run(["magick", logo_path, "-background", "none", "-alpha", "on", converted], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
                    logo_path = converted
                margin = int(self.bottom_margin.get())
                ns = int(self.neg_size.get())
                ls = int(self.logo_size.get())
                size = int(self.font_size.get())
                font = ffmpeg_escape(self.font.get())
                tbl = ffmpeg_escape(self.tbl_text.get())
                corp = ffmpeg_escape(self.corp_text.get())
                tbl_color = self.tbl_color.lstrip("#")
                corp_color = self.corp_color.lstrip("#")
                graph = (
                    f"[1:v]scale={ns}:{ns}:force_original_aspect_ratio=decrease,pad={ns}:{ns}:(ow-iw)/2:(oh-ih)/2:color=0x00000000,format=rgba,colorchannelmixer=aa=0.96[neg];"
                    f"[2:v]scale={ls}:{ls}:force_original_aspect_ratio=decrease,pad={ls}:{ls}:(ow-iw)/2:(oh-ih)/2:color=0x00000000,format=rgba,colorchannelmixer=aa=0.96[tbl];"
                    f"[0:v][tbl]overlay=300:H-h-{margin}:format=auto[tmp];[tmp][neg]overlay=W-{ns+330}:H-h-{margin}:format=auto[logos];"
                    f"[logos]drawtext=font='{font}':text='{tbl}':fontcolor=0x{tbl_color}:fontsize={size}:borderw=2:bordercolor=0x17102B:shadowcolor=0x7B2CFF@0.9:shadowx=2:shadowy=2:x=48:y=H-text_h-{margin},"
                    f"drawtext=font='{font}':text='{corp}':fontcolor=0x{corp_color}:fontsize={size}:borderw=2:bordercolor=0x17102B:shadowcolor=0x00E5FF@0.85:shadowx=2:shadowy=2:x=W-text_w-48:y=H-text_h-{margin},format=yuv420p[out]"
                )
                cmd = ["ffmpeg", "-hide_banner", "-y", "-i", self.video.get(), "-loop", "1", "-framerate", "30", "-i", self.neg.get(), "-loop", "1", "-framerate", "30", "-i", logo_path, "-filter_complex", graph, "-map", "[out]", "-map", "0:a?", "-t", str(int(self.duration.get())), "-c:v", "libx264", "-preset", self.preset.get(), "-threads", str(int(self.threads.get())), "-crf", "21", "-c:a", "aac", "-b:a", "160k", "-shortest", "-movflags", "+faststart", str(out)]
                with open(os.devnull, "w") as devnull:
                    subprocess.run(["nice", "-n", "10", *cmd], check=True, stdout=devnull, stderr=subprocess.PIPE, text=True)
            self.after(0, lambda: self._finish(True, f"Created: {out}"))
        except subprocess.CalledProcessError as e:
            detail = e.stderr[-1800:] if e.stderr else str(e)
            self.after(0, lambda d=detail: self._finish(False, "FFmpeg failed. Details:\n" + d))
        except Exception as e:
            self.after(0, lambda d=str(e): self._finish(False, d))

    def _finish(self, ok: bool, message: str):
        self.render_button.configure(state="normal")
        self.status.set(message if len(message) < 130 else message[:127] + "…")
        if ok:
            messagebox.showinfo(APP_NAME, message + "\n\nOpen Desktop and Wallpaper settings and select the generated MP4 in your video wallpaper plugin.")
        else:
            messagebox.showerror(APP_NAME, message)


if __name__ == "__main__":
    WallpaperStudio().mainloop()
