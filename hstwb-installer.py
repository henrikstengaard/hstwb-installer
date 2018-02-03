# https://www.begueradj.com/tkinter-best-practices.html
# https://stackoverflow.com/questions/34276663/tkinter-gui-layout-using-frames-and-grid

import Tkinter as Tk
import tkFont as tkFont

class MainApplication(Tk.Frame):

    def __init__(self, master):
        self.master = master
        Tk.Frame.__init__(self, self.master)
        self.configure_gui()
        self.create_widgets()
        self.pack(side="top", fill="both", expand=True)

    def configure_gui(self):
        self.master.iconbitmap(r'hstwb_installer.ico')
        self.master.title('HstWB Installer v2.0.0')
        self.master.geometry('{}x{}'.format(460, 550))
        self.master.resizable(False, False)
        self.center()

    def center(self):
        self.update_idletasks()
        width = self.master.winfo_width()
        height = self.master.winfo_height()
        x = (self.master.winfo_screenwidth() // 2) - (width // 2)
        y = (self.master.winfo_screenheight() // 2) - (height // 2)
        self.master.geometry('{}x{}+{}+{}'.format(width, height, x, y))

    def create_widgets(self):
        # self.grid_rowconfigure(0, weight=1)
        self.grid_columnconfigure(0, weight=1)

        self.font = tkFont.Font(family="TopazPlus a600a1200a4000", size=9, weight=tkFont.NORMAL)

        self.workbench_frame = Tk.LabelFrame(self, text="Workbench")
        self.workbench_frame.grid(row=0, sticky="ew", padx=(5, 5), pady=(5))
        self.workbench_frame.grid_rowconfigure(0, weight=1)
        self.workbench_frame.grid_columnconfigure(0, weight=1)

        self.install_workbench = True

        self.install_workbench_checkbutton = Tk.Checkbutton(self.workbench_frame, text="Install Workbench 3.1", variable=self.install_workbench)
        self.install_workbench_checkbutton.grid(row=0, column=0, columnspan=2, sticky="w")

        self.workbench_set_dir_entry = Tk.Entry(self.workbench_frame)
        self.workbench_set_dir_entry.grid(row=1, column=0, columnspan=2, sticky="ew")

        self.workbench_set_dir_button = Tk.Button(self.workbench_frame, text="...")
        self.workbench_set_dir_button.grid(row=1, column=2, columnspan=1, sticky="e")

        # Create a Tkinter variable
        self.tkvar = Tk.StringVar(self)

        # Dictionary with options
        self.choices = { 'Cloanto Amiga Forever 7','Cloanto Amiga Forever 2016', 'Custom'}
        self.tkvar.set('Cloanto Amiga Forever 7') # set the default option

        self.workbench_set_option_menu = Tk.OptionMenu(self.workbench_frame, self.tkvar, *self.choices)
        #self.workbench_set_option_menu.config(bg="GREEN")
        self.workbench_set_option_menu.grid(row=2, column=0, columnspan=3, sticky="ew")

        self.kickstart_frame = Tk.LabelFrame(self, text="Kickstart")
        self.kickstart_frame.grid(row=1, sticky="ew", padx=(5, 5), pady=(5))
        self.kickstart_frame.grid_rowconfigure(0, weight=1)
        self.kickstart_frame.grid_columnconfigure(0, weight=1)

        self.install_kickstart = True

        self.install_kickstart_checkbutton = Tk.Checkbutton(self.kickstart_frame, text="Install Kickstart", variable=self.install_kickstart)
        self.install_kickstart_checkbutton.grid(row=0, column=0, columnspan=2, sticky="w")

        self.kickstart_rom_dir_entry = Tk.Entry(self.kickstart_frame)
        self.kickstart_rom_dir_entry.grid(row=1, column=0, columnspan=2, sticky="ew")

        self.kickstart_rom_dir_button = Tk.Button(self.kickstart_frame, text="...")
        self.kickstart_rom_dir_button.grid(row=1, column=2, columnspan=1, sticky="e")

        self.kickstart_rom_sets = { 'Cloanto Amiga Forever 7/2016', 'Custom'}
        self.kickstart_rom_set = Tk.StringVar(self)
        self.kickstart_rom_set.set('Cloanto Amiga Forever 7/2016') # set the default option

        self.kickstart_rom_set_option_menu = Tk.OptionMenu(self.kickstart_frame, self.kickstart_rom_set, *self.kickstart_rom_sets)
        #self.kickstart_rom_set_option_menu.config(bg="GREEN", activebackground="GREEN")
        self.kickstart_rom_set_option_menu.grid(row=2, column=0, columnspan=3, sticky="ew")

        self.amigaos39_frame = Tk.LabelFrame(self, text="Amiga OS 3.9")
        self.amigaos39_frame.grid(row=2, sticky="ew", padx=(5, 5), pady=(5))
        self.amigaos39_frame.grid_rowconfigure(0, weight=1)
        self.amigaos39_frame.grid_columnconfigure(1, weight=1)

        self.install_amigaos39_label = Tk.Label(self.amigaos39_frame, text="Install Amiga OS 3.9")
        self.install_amigaos39_label.grid(row=0, column=0, sticky="w")

        self.install_amigaos39_checkbutton = Tk.Checkbutton(self.amigaos39_frame)
        self.install_amigaos39_checkbutton.grid(row=0, column=1, columnspan=2, sticky="w")

        self.install_boingbags_label = Tk.Label(self.amigaos39_frame, text="Install Boing Bags")
        self.install_boingbags_label.grid(row=1, column=0, sticky="w")

        self.install_boingbags_checkbutton = Tk.Checkbutton(self.amigaos39_frame)
        self.install_boingbags_checkbutton.grid(row=1, column=1, columnspan=2, sticky="w")

        self.amigaos39_iso_file_label = Tk.Label(self.amigaos39_frame, text="Amiga OS 3.9 iso file")
        self.amigaos39_iso_file_label.grid(row=2, column=0, sticky="w")

        self.amigaos39_iso_file_entry = Tk.Entry(self.amigaos39_frame)
        self.amigaos39_iso_file_entry.grid(row=2, column=1, columnspan=2, sticky="ew")

        self.amigaos39_iso_file_button = Tk.Button(self.amigaos39_frame, text="...")
        self.amigaos39_iso_file_button.grid(row=2, column=2, sticky="e")

        # packages
        self.packages_frame = Tk.LabelFrame(self, text="Packages")
        self.packages_frame.grid(row=3, sticky="ew", padx=(5, 5), pady=(5))
        self.packages_frame.grid_rowconfigure(0, weight=1)
        self.packages_frame.grid_columnconfigure(0, weight=1)


        self.packages_scrollbar = Tk.Scrollbar(self.packages_frame, orient=Tk.VERTICAL)
        self.packages_listbox = Tk.Listbox(self.packages_frame, selectmode=Tk.EXTENDED, height=5, yscrollcommand=self.packages_scrollbar.set)
        self.packages_scrollbar.config(command=self.packages_listbox.yview)
        self.packages_scrollbar.pack(side=Tk.RIGHT, fill=Tk.Y)
        self.packages_listbox.pack(side=Tk.LEFT, fill=Tk.BOTH, expand=1)

        # self.packages_listbox = Tk.Listbox(self.packages_frame, selectmode=Tk.EXTENDED)
        # self.packages_listbox.grid(row=0, column=0, sticky="ew")
        self.packages_listbox.insert(Tk.END, "BetterWB v4.0.3")
        self.packages_listbox.insert(Tk.END, "HstWB v1.0.2")
        self.packages_listbox.insert(Tk.END, "EAB WHDLoad Games AGA v3.0.0")
        self.packages_listbox.insert(Tk.END, "EAB WHDLoad Games AGA v3.0.0")
        self.packages_listbox.insert(Tk.END, "EAB WHDLoad Games AGA v3.0.0")
        self.packages_listbox.insert(Tk.END, "EAB WHDLoad Games AGA v3.0.0")
        self.packages_listbox.insert(Tk.END, "EAB WHDLoad Games AGA v3.0.0")
        self.packages_listbox.insert(Tk.END, "EAB WHDLoad Games AGA v3.0.0")

if __name__ == '__main__':
   root = Tk.Tk()
   main_app =  MainApplication(root)
   root.mainloop()