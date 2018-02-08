"""Packages"""

import Tkinter as Tk

class PackagesTabModel(object):
    """Packages Tab Model"""
    def __init__(self, controller):
        """Init"""
        self.controller = controller
        self.packages = [
            'BetterWB v4.0.3',
            'HstWB v1.0.2',
            'EAB WHDLoad Games AGA v3.0.0',
            'EAB WHDLoad Games OCS v3.0.0' ]
        self.selected_packages = [
            'HstWB v1.0.2',
            'EAB WHDLoad Games OCS v3.0.0' ]

    def model_did_change(self):
        """Model did change"""
        self.controller.listChangedDelegate()

    def get_packages(self):
        """Get packages"""
        return self.packages

    def set_list(self, packages):
        """Set list"""
        self.packages = packages
        #self.modelDidChange #delegate called on change

class PackagesTabController(object):
    """Packages tab controller"""
    def __init__(self, parent):
        self.parent = parent
        self.model = PackagesTabModel(self)
        self.view = PackagesTabView(self)
        self.update_packages()

    def update_packages(self):
        """Update packages"""
        for index,package in enumerate(self.model.packages):
            self.view.packages_listbox.insert(Tk.END, package)
            if package in self.model.selected_packages:
                self.view.packages_listbox.selection_set(index)

    def selected_packages_changed(self, evt):
        """Selected packages changed"""
        self.model.selected_packages = []
        widget = evt.widget
        for index in widget.curselection():
            self.model.selected_packages.append(widget.get(index))

class PackagesTabView(Tk.Frame):
    """Packages tab view"""
    def __init__(self, controller):
        self.controller = controller
        Tk.Frame.__init__(self)
        self.grid_rowconfigure(0, weight=1)
        self.grid_columnconfigure(0, weight=1)
        self.create_widgets()

    def create_widgets(self):
        """Create widgets"""
        self.packages_frame = Tk.LabelFrame(self, text="Packages")
        self.packages_frame.grid(row=0, sticky="nesw", padx=(5, 5), pady=(5))
        self.packages_frame.grid_rowconfigure(0, weight=1)
        self.packages_frame.grid_columnconfigure(0, weight=1)

        self.packages_scrollbar = Tk.Scrollbar(self.packages_frame, orient=Tk.VERTICAL)
        self.packages_listbox = Tk.Listbox(
            self.packages_frame,
            selectmode=Tk.EXTENDED,
            yscrollcommand=self.packages_scrollbar.set)
        self.packages_scrollbar.config(command=self.packages_listbox.yview)
        self.packages_scrollbar.pack(side=Tk.RIGHT, fill=Tk.Y, padx=(0, 5), pady=(5))
        self.packages_listbox.pack(side=Tk.LEFT, fill=Tk.BOTH, padx=(5, 0), pady=(5), expand=1)
        self.packages_listbox.bind('<<ListboxSelect>>', self.controller.selected_packages_changed)
