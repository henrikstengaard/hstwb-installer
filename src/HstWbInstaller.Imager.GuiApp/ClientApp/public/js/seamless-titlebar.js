(function(){
    const { ipcRenderer } = window.require("electron");

    // initialise window controls, when document is loaded and complete 
    document.onreadystatechange = (event) => {
        if (document.readyState === "complete") {
            initWindowControls();
        }
    };

    function initWindowControls() {
        document.getElementById('minimize-button').addEventListener("click", event => {
            ipcRenderer.send("minimize-window");
        });

        document.getElementById('maximize-button').addEventListener("click", event => {
            ipcRenderer.send("maximize-window");
        });

        document.getElementById('restore-button').addEventListener("click", event => {
            ipcRenderer.send("unmaximize-window");
        });

        document.getElementById('close-button').addEventListener("click", event => {
            ipcRenderer.send("close-window");
        });
    }

    ipcRenderer.on('window-maximized', (event, arg) => {
        document.body.classList.add('maximized');
    });

    ipcRenderer.on('window-unmaximized', (event, arg) => {
        document.body.classList.remove('maximized');
    });
}());