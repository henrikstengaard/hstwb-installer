import React from 'react'
import { styled } from '@mui/system'

// const titlebar = styled('header')(({ theme }) => ({
//     color: theme.palette.primary.contrastText,
//     backgroundColor: theme.palette.primary.main,
//     padding: theme.spacing(1),
//     borderRadius: theme.shape.borderRadius,
// }));
//
// const useStyles = makeStyles(theme => ({
//     titlebar: {
//         padding: '3px',
//         userSelect: 'none',
//         display: 'block',
//         position: 'fixed',
//         height: '32px',
//         width: '100%',
//         backgroundColor: 'rgba(100, 100, 100)'
//     },
//     dragRegion: {
//         width: '100%',
//         height: '100%',
//         display: 'grid',
//         gridTemplateColumns: 'auto 138px',
//         '-webkit-app-region': 'drag'
//     },
//     windowTitle: {
//         color: 'white',
//         gridColumn: '1',
//         display: 'flex',
//         alignItems: 'center',
//         overflow: 'hidden',
//         fontSize: '14px'
//     },
//     windowIcon: {
//         marginRight: '4px'
//     },
//     windowName: {
//         marginTop: '3px',
//         overflow: 'hidden',
//         textOverflow: 'ellipsis',
//         whiteSpace: 'nowrap',
//         lineHeight: '1.5'
//     },
//     windowControls: {
//         display: 'grid',
//         gridTemplateColumns: 'repeat(3, 46px)',
//         position: 'absolute',
//         top: '0',
//         right: '0',
//         height: '100%',
//         '-webkit-app-region': 'no-drag'
//     },
//     button: {
//         gridRow: '1 / span 1',
//         display: 'flex',
//         justifyContent: 'center',
//         alignItems: 'center',
//         width: '100%',
//         height: '100%',
//         userSelect: 'none',
//         '&:hover': {
//             background: 'rgba(255,255,255,0.1)'
//         },
//         '&:active': {
//             background: 'rgba(255,255,255,0.2)'            
//         }
//     },
//     minimizeButton: {
//         gridColumn: '1'
//     },
//     maximizeButton: {
//         gridColumn: '2',
//     },
//     restoreButton: {
//         gridColumn: '2'
//     },
//     closeButton: {
//         gridColumn: '3',
//         '&:hover': {
//             background: '#E81123 !important'
//         },
//         '&:active': {
//             background: '#F1707A !important'
//         }
//     },
//     icon: {
//         width: '10px',
//         height: '10px'
//     },
//     main: {
//         paddingTop: '42px',
//         overflowY: 'auto'
//     }
// }))

export default function SeamlessTitlebarLayout(props) {
    const [maximized, setMaximized] = React.useState(false)
    // const classes = useStyles()
    
    const electronIpcSend = (message) => {
        if (!window.require) {
            return
        }
        const { ipcRenderer } = window.require("electron")
        ipcRenderer.send(message);
    }

    const handleMinimizeWindow = () => {
        electronIpcSend('minimize-window')
    }
    
    const handleMaximizeWindow = () => {
        electronIpcSend('maximize-window')
    }

    const handleRestoreWindow = () => {
        electronIpcSend('unmaximize-window')
    }
    
    const handleCloseWindow = () => {
        electronIpcSend('close-window')
    }
    
    if (window.require) {
        const { ipcRenderer } = window.require("electron")
        ipcRenderer.on('window-maximized', (event, arg) => {
            setMaximized(true)
        });
        ipcRenderer.on('window-unmaximized', (event, arg) => {
            setMaximized(false)
        });
    }
    
    const {
        children
    } = props
    
    return (
        <React.Fragment>
            {/*<header className={classes.titlebar}>*/}
            {/*    <div className={classes.dragRegion}>*/}
            {/*        <div className={classes.windowTitle}>*/}
            {/*            <img  className={classes.windowIcon} src="icons/icon-192x192.png" height="16px" alt="Icon"/>*/}
            {/*            <span className={classes.windowName}>HstWB Installer Imager</span>*/}
            {/*        </div>*/}
            
            {/*        <div className={classes.windowControls}>*/}
            {/*            <div className={`${classes.button} ${classes.minimizeButton}`} onClick={() => handleMinimizeWindow()}>*/}
            {/*                <img className={classes.icon} src="icons/min-w-10.png"*/}
            {/*                     srcSet="icons/min-w-10.png 1x, icons/min-w-12.png 1.25x, icons/min-w-15.png 1.5x, icons/min-w-15.png 1.75x, icons/min-w-20.png 2x, icons/min-w-20.png 2.25x, icons/min-w-24.png 2.5x, icons/min-w-30.png 3x, icons/min-w-30.png 3.5x"*/}
            {/*                     draggable="false" alt="Minimize"/>*/}
            {/*            </div>*/}
            {/*            {!maximized && (*/}
            {/*                <div className={`${classes.button} ${classes.maximizeButton}`} onClick={() => handleMaximizeWindow()}>*/}
            {/*                    <img className={classes.icon} src="icons/max-w-10.png"*/}
            {/*                         srcSet="icons/max-w-10.png 1x, icons/max-w-12.png 1.25x, icons/max-w-15.png 1.5x, icons/max-w-15.png 1.75x, icons/max-w-20.png 2x, icons/max-w-20.png 2.25x, icons/max-w-24.png 2.5x, icons/max-w-30.png 3x, icons/max-w-30.png 3.5x"*/}
            {/*                         draggable="false" alt="Maximize"/>*/}
            {/*                </div>*/}
            {/*            )}*/}
            {/*            {maximized && (*/}
            {/*                <div className={`${classes.button} ${classes.restoreButton}`} onClick={() => handleRestoreWindow()}>*/}
            {/*                    <img className={classes.icon} src="icons/restore-w-10.png"*/}
            {/*                         srcSet="icons/restore-w-10.png 1x, icons/restore-w-12.png 1.25x, icons/restore-w-15.png 1.5x, icons/restore-w-15.png 1.75x, icons/restore-w-20.png 2x, icons/restore-w-20.png 2.25x, icons/restore-w-24.png 2.5x, icons/restore-w-30.png 3x, icons/restore-w-30.png 3.5x"*/}
            {/*                         draggable="false" alt="Restore"/>*/}
            {/*                </div>*/}
            {/*            )}*/}
            {/*            <div className={`${classes.button} ${classes.closeButton}`} onClick={() => handleCloseWindow()}>*/}
            {/*                <img className={classes.icon} src="icons/close-w-10.png"*/}
            {/*                     srcSet="icons/close-w-10.png 1x, icons/close-w-12.png 1.25x, icons/close-w-15.png 1.5x, icons/close-w-15.png 1.75x, icons/close-w-20.png 2x, icons/close-w-20.png 2.25x, icons/close-w-24.png 2.5x, icons/close-w-30.png 3x, icons/close-w-30.png 3.5x"*/}
            {/*                     draggable="false" alt="Close"/>*/}
            {/*            </div>*/}
            {/*        </div>*/}
            {/*    </div>*/}
            {/*</header>*/}
            
            {/*<div className={classes.main}>*/}
            {/*    {children}*/}
            {/*</div>*/}
        </React.Fragment>
    );
}