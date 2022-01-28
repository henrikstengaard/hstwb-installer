import * as React from 'react'
import {useHistory} from 'react-router-dom'
import Box from '@material-ui/core/Box'
import Grid from '@material-ui/core/Grid'
import List from '@material-ui/core/List'
import ListItem from '@material-ui/core/ListItem'
import Link from '@material-ui/core/Link'
import Popover from '@material-ui/core/Popover'

export default function AppMenu() {
    const history = useHistory()

    const [fileAnchorEl, setFileAnchorEl] = React.useState(null);
    const [modeAnchorEl, setModeAnchorEl] = React.useState(null);
    const fileOpen = Boolean(fileAnchorEl);
    const modeOpen = Boolean(modeAnchorEl);
    const handleFileClick = (event) => {
        setFileAnchorEl(event.currentTarget);
    };
    const handleModeClick = (event) => {
        setModeAnchorEl(event.currentTarget);
    };
    const handleClose = () => {
        setFileAnchorEl(null);
        setModeAnchorEl(null);
    };
    const electronIpcSend = (message) => {
        if (!window.require) {
            return
        }
        const { ipcRenderer } = window.require("electron")
        ipcRenderer.send(message);
    }
    const handleExit = () => {
        electronIpcSend('close-window')
    };
    const handleRedirect = (path) => {
        handleClose()
        history.push(path)
    }
    const fileId = modeOpen ? 'file-popover' : undefined;
    const modeId = modeOpen ? 'mode-popover' : undefined;

    return (
        <Box style={{
            display: 'block',
            position: 'fixed',
            width: '100%',
            top: '32px',
            padding: '4px',
            backgroundColor: 'rgba(100, 100, 100)'
        }}>
            <Grid container spacing={1}>
                <Grid item>
                    <Link onClick={handleFileClick} style={{ fontSize: '14px', color: 'white' }}>
                        File
                    </Link>
                    <Popover
                        id={fileId}
                        open={fileOpen}
                        anchorEl={fileAnchorEl}
                        onClose={handleClose}
                        anchorOrigin={{
                            vertical: 'bottom',
                            horizontal: 'left',
                        }}
                        TransitionProps={{ timeout: 0 }}
                    >
                        <List dense>
                            <ListItem button onClick={handleExit}>Exit</ListItem>
                        </List>
                    </Popover>
                </Grid>
                <Grid item>
                    <Link onClick={handleModeClick} style={{ fontSize: '14px', color: 'white' }}>
                        Mode
                    </Link>
                    <Popover
                        id={modeId}
                        open={modeOpen}
                        anchorEl={modeAnchorEl}
                        onClose={handleClose}
                        anchorOrigin={{
                            vertical: 'bottom',
                            horizontal: 'left',
                        }}
                        TransitionProps={{ timeout: 0 }}
                        onMouseLeave={handleClose}
                    >
                        <List dense>
                            <ListItem button onClick={() => handleRedirect('/read')}>Read</ListItem>
                            <ListItem button onClick={() => handleRedirect('/write')}>Write</ListItem>
                            <ListItem button onClick={() => handleRedirect('/convert')}>Convert</ListItem>
                            <ListItem button onClick={() => handleRedirect('/verify')}>Verify</ListItem>
                            <ListItem button onClick={() => handleRedirect('/blank')}>Blank</ListItem>
                            <ListItem button onClick={() => handleRedirect('/optimize')}>Optimize</ListItem>
                        </List>
                    </Popover>
                </Grid>
            </Grid>
        </Box>
    );
}