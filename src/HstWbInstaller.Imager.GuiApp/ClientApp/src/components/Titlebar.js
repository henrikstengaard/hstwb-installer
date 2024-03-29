import React from 'react'
import Box from '@mui/material/Box'
import AppBar from '@mui/material/AppBar'
import Toolbar from '@mui/material/Toolbar'
import Typography from '@mui/material/Typography'
import IconButton from '@mui/material/IconButton'
import {FontAwesomeIcon} from '@fortawesome/react-fontawesome'
import {ElectronIpc} from "../utils/ElectronIpc"
import {HSTWB_INSTALLER_VERSION} from '../Constants'

export default function Titlebar() {
    const [maximized, setMaximized] = React.useState(false)
    const electronIpc = new ElectronIpc()

    const handleMinimizeWindow = () => {
        electronIpc.send({message: 'minimize-window'})
    }

    const handleMaximizeWindow = () => {
        electronIpc.send({message: 'maximize-window'})
    }

    const handleRestoreWindow = () => {
        electronIpc.send({message: 'unmaximize-window'})
    }

    const handleCloseWindow = () => {
        electronIpc.send({message: 'close-window'})
    }

    electronIpc.on({event: 'window-maximized', callback: () => setMaximized(true)})
    electronIpc.on({event: 'window-unmaximized', callback: () => setMaximized(false)})

    return (
        <AppBar
            position="fixed"
            sx={{
                zIndex: (theme) => theme.zIndex.drawer + 10000,
                WebkitAppRegion: 'drag',
                userSelect: 'none'
            }}
        >
            <Toolbar disableGutters style={{minHeight: '32px', padding: '7px'}}>
                <img src="icons/icon-192x192.png" height="20px" alt="HstWB Installer app icon"
                     style={{paddingLeft: '2px', paddingRight: '2px'}}/>
                <Typography variant="h1" component="div" sx={{flexGrow: 1}}>
                    HstWB Imager v{HSTWB_INSTALLER_VERSION}
                </Typography>
                <Box style={{WebkitAppRegion: 'no-drag'}}>
                    <IconButton
                        disableRipple={true}
                        size="small"
                        color="inherit"
                        aria-label="minimize"
                        onClick={() => handleMinimizeWindow()}
                    >
                        <FontAwesomeIcon icon="window-minimize"/>
                    </IconButton>
                    {!maximized && (
                        <IconButton
                            disableRipple={true}
                            size="small"
                            color="inherit"
                            aria-label="maximize"
                            onClick={() => handleMaximizeWindow()}
                        >
                            <FontAwesomeIcon icon="window-maximize"/>
                        </IconButton>
                    )}
                    {maximized && (
                        <IconButton
                            disableRipple={true}
                            size="small"
                            color="inherit"
                            aria-label="restore"
                            onClick={() => handleRestoreWindow()}
                        >
                            <FontAwesomeIcon icon="window-restore"/>
                        </IconButton>
                    )}
                    <IconButton
                        disableRipple={true}
                        size="small"
                        color="inherit"
                        aria-label="close"
                        onClick={() => handleCloseWindow()}
                    >
                        <FontAwesomeIcon icon="window-close"/>
                    </IconButton>
                </Box>
            </Toolbar>
        </AppBar>
    )
}
