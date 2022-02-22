import { get, isNil } from 'lodash'
import React from "react";
import {AppStateContext} from "./AppStateContext";
import IconButton from "@mui/material/IconButton";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import {HubConnectionBuilder} from "@microsoft/signalr";

export default function BrowseOpenDialog(props) {
    const {
        id,
        title = 'Open file',
        fileFilters = [{
            name: 'Image file',
            extensions: ['img', 'hdf']
        }, {
            name: 'Virtual hard disk',
            extensions: ['vhd']
        }],
        onChange
    } = props

    const appState = React.useContext(AppStateContext)
    const [ connection, setConnection ] = React.useState(null);

    React.useEffect(() => {
        const newConnection = new HubConnectionBuilder()
            .withUrl('/hubs/show-dialog-result')
            .withAutomaticReconnect()
            .build();

        setConnection(newConnection);
    }, []);

    React.useEffect(() => {
        if (connection && connection.state !== "Connected") {
            connection.start()
                .then(result => {
                    connection.on('ShowDialogResult', showDialogResult => {
                        if (get(showDialogResult, 'isSuccess') !== true || get(showDialogResult, 'id') !== id) {
                            return
                        }

                        if (isNil(onChange)) {
                            return
                        }
                        
                        onChange(showDialogResult.paths[0])
                    });
                })
                .catch(e => console.log('Connection failed: ', e));
        }
    }, [connection, id, onChange]);

    const handleBrowseClick = async () => {
        if (!appState || !appState.isElectronActive)
        {
            console.error('Browse open dialog is only available with Electron')
            return
        }

        const response = await fetch('show-open-dialog', {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                id,
                title,
                fileFilters
            })
        });
        if (!response.ok) {
            console.error('Failed to show open dialog')
        }
    }

    return (
        <React.Fragment>
            <IconButton aria-label="browse" disableRipple onClick={async () => await handleBrowseClick()}>
                <FontAwesomeIcon icon="ellipsis-h"/>
            </IconButton>
        </React.Fragment>
    )
}