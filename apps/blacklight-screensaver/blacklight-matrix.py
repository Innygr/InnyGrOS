#!/usr/bin/env python3
"""Fullscreen, local-only Blacklight Matrix visual. It is not a security lock screen."""
import random
import sys

try:
    import tkinter as tk
except ModuleNotFoundError:
    print(
        "Blacklight Matrix needs Python Tkinter. On Kubuntu/Ubuntu, run:\n"
        "  sudo apt update && sudo apt install python3-tk",
        file=sys.stderr,
    )
    raise SystemExit(1)

BG = "#020604"
GREEN = "#3cff86"
DIM = "#0d6034"
WIDTH_HINT = 1280
HEIGHT_HINT = 720


class BlacklightMatrix:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("InnyGrOS Blacklight Matrix")
        self.root.configure(bg=BG)
        self.root.attributes("-fullscreen", True)
        self.root.attributes("-topmost", True)
        self.canvas = tk.Canvas(self.root, bg=BG, highlightthickness=0, cursor="none")
        self.canvas.pack(fill="both", expand=True)
        self.columns = []
        self.running = True
        self.root.bind("<Escape>", self.close)
        self.root.bind("<Key>", self.close)
        self.root.bind("<Button>", self.close)
        self.root.bind("<Motion>", self.motion)
        self.last_mouse = None
        self.root.after(100, self.initialize)
        self.root.mainloop()

    def initialize(self):
        self.width = max(self.root.winfo_width(), WIDTH_HINT)
        self.height = max(self.root.winfo_height(), HEIGHT_HINT)
        self.font_size = 16
        self.column_count = max(1, self.width // self.font_size)
        self.columns = [
            {"y": random.randint(-self.height, self.height),
             "speed": random.randint(2, 9),
             "length": random.randint(5, 18)}
            for _ in range(self.column_count)
        ]
        self.draw()

    def close(self, _event=None):
        self.running = False
        self.root.destroy()

    def motion(self, event):
        pos = (event.x_root, event.y_root)
        if self.last_mouse is not None and pos != self.last_mouse:
            self.close()
        self.last_mouse = pos

    def draw(self):
        if not self.running:
            return
        self.canvas.delete("rain")
        self.canvas.delete("overlay")
        glyphs = "01アイウエオカキクケコサシスセソ"
        for col_index, col in enumerate(self.columns):
            x = col_index * self.font_size
            for offset in range(col["length"]):
                y = col["y"] - offset * self.font_size
                if 0 <= y < self.height:
                    glyph = random.choice(glyphs)
                    color = GREEN if offset == 0 else DIM
                    self.canvas.create_text(
                        x, y, text=glyph, fill=color, font=("monospace", self.font_size),
                        anchor="nw", tags="rain"
                    )
            col["y"] += col["speed"]
            if col["y"] - col["length"] * self.font_size > self.height:
                col["y"] = random.randint(-self.height // 2, 0)
                col["speed"] = random.randint(2, 9)
                col["length"] = random.randint(5, 18)

        center_x = self.width // 2
        center_y = self.height // 2
        self.canvas.create_rectangle(
            center_x - 280, center_y - 115, center_x + 280, center_y + 115,
            fill="#06120a", outline="#1b9d50", width=2, tags="overlay"
        )
        self.canvas.create_text(
            center_x, center_y - 42, text="INNYGRCORP", fill=GREEN,
            font=("monospace", 30, "bold"), tags="overlay"
        )
        self.canvas.create_text(
            center_x, center_y + 2, text="// BLACKLIGHT MATRIX", fill="#b2ffd0",
            font=("monospace", 16), tags="overlay"
        )
        self.canvas.create_line(
            center_x - 210, center_y + 35, center_x + 210, center_y + 35,
            fill="#286b42", width=1, tags="overlay"
        )
        self.canvas.create_text(
            center_x, center_y + 64, text="SYSTEM IDLE  //  PRESS ANY KEY TO RETURN",
            fill="#7ca98b", font=("monospace", 10), tags="overlay"
        )
        self.root.after(55, self.draw)


if __name__ == "__main__":
    BlacklightMatrix()
