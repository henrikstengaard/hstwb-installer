import Tkinter as Tk

class PackagesTabModel():
    """Packages Tab Model"""
    def __init__(self, controller):
        """Init"""
        #set delegate/callback pointer
        self.controller = controller
        #initialize model
        self.packages = { 'BetterWB v4.0.3', 'HstWB v1.0.2', 'EAB WHDLoad Games AGA v3.0.0', 'EAB WHDLoad Games AGA v3.0.0'}
        self.install_packages = { 'HstWB v1.0.2' }

#Delegate goes here. Model would call this on internal change
    def modelDidChange(self):
        self.controller.listChangedDelegate()

#Setters and getters for the model
    def getPackages(self):
        return self.packages

    def set_list(self, packages):
        self.packages = packages
        self.modelDidChange #delegate called on change

class PackagesTabController():
    def __init__(self, parent):
        self.parent = parent
        self.model = PackagesTabModel(self)    # initializes the model
        self.view = PackagesTabView(self)  #initializes the view
 
        #initialize properties in view, if any
        pass

    def listChanged(self, evt):
        #model internally chages and needs to signal a change
        #print(self.model.getList())
        print 'List changed'
        w = evt.widget
        for index in w.curselection():
            value = w.get(index) 
            #index = int(w.curselection()[0])
            #value = w.get(index)
            print 'You selected item %d: "%s"' % (index, value)

#event handlers -- add functions called by command attribute in view
    def someHandelerMethod(self):
        pass
#delegates -- add functions called by delegtes in model or view
    def modelDidChangeDelegate(self):
        pass

class PackagesTabView(Tk.Frame):
    def __init__(self, controller):
        self.controller = controller
        Tk.Frame.__init__(self)
        self.grid_rowconfigure(0, weight=1)
        self.grid_columnconfigure(0, weight=1)
        self.create_widgets()

    def create_widgets(self):
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
        self.packages_scrollbar.pack(side=Tk.RIGHT, fill=Tk.Y)
        self.packages_listbox.pack(side=Tk.LEFT, fill=Tk.BOTH, expand=1)
        self.packages_listbox.bind('<<ListboxSelect>>', self.controller.listChanged)

        self.packages_listbox.insert(Tk.END, "BetterWB v4.0.3")
        self.packages_listbox.insert(Tk.END, "HstWB v1.0.2")
        self.packages_listbox.insert(Tk.END, "EAB WHDLoad Games AGA v3.0.0")
        self.packages_listbox.insert(Tk.END, "EAB WHDLoad Games AGA v3.0.0")
        self.packages_listbox.insert(Tk.END, "EAB WHDLoad Games AGA v3.0.0")
        self.packages_listbox.insert(Tk.END, "EAB WHDLoad Games AGA v3.0.0")
        self.packages_listbox.insert(Tk.END, "EAB WHDLoad Games AGA v3.0.0")
        self.packages_listbox.insert(Tk.END, "EAB WHDLoad Games AGA v3.0.0")

