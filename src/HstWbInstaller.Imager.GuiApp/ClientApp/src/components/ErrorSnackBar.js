import React from 'react';
import Snackbar from '@mui/material/Snackbar';
import IconButton from '@mui/material/IconButton';
import {Alert} from "@mui/material";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import {HubConnectionBuilder} from "@microsoft/signalr";

const initialState = {
    open: false,
    errorMessage: null
}

export default function ErrorSnackBar() {
    const [state, setState] = React.useState({...initialState});
    const [connection, setConnection] = React.useState(null);

    React.useEffect(() => {
        const newConnection = new HubConnectionBuilder()
            .withUrl('/hubs/error')
            .withAutomaticReconnect()
            .build();

        setConnection(newConnection);
    }, []);

    React.useEffect(() => {
        if (connection && connection.state !== "Connected") {
            connection.start()
                .then(result => {
                    connection.on('UpdateError', error => {
                        setState({
                            ...state,
                            open: true,
                            errorMessage: error.message
                        })
                    });
                })
                .catch(e => console.log('Connection failed: ', e));
        }
    }, [connection, setState, state]);
    
    const handleClose = (event, reason) => {
        if (reason === 'clickaway') {
            return;
        }

        setState({
            ...state,
            open: false
        });
    };
    
    const action = (
        <React.Fragment>
            <IconButton
                size="small"
                aria-label="close"
                color="inherit"
                onClick={() => handleClose()}
            >
                <FontAwesomeIcon icon="times" />
            </IconButton>
        </React.Fragment>
    );
    
    const {
        open,
        errorMessage
    } = state
    
    return (
        <Snackbar
            anchorOrigin={{
                vertical: 'bottom',
                horizontal: 'right'
        }}
            open={open}
            autoHideDuration={5000}
            onClose={() => handleClose()}
            action={action}
        >
            <Alert onClose={() => handleClose()} severity="error" sx={{ width: '100%' }}>
                {errorMessage}
            </Alert>            
        </Snackbar>
    )
}