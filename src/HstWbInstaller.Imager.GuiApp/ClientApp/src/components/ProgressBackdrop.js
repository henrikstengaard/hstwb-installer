import { get } from 'lodash'
import React from 'react'
import Container from '@mui/material/Container'
import Box from '@mui/material/Box'
import Backdrop from '@mui/material/Backdrop'
import LinearProgress from '@mui/material/LinearProgress'
import {styled} from '@mui/system'
import {Button} from "@mui/material"
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome"
import Card from "@mui/material/Card"
import CardContent from "@mui/material/CardContent"
import Typography from "@mui/material/Typography"
import {HubConnectionBuilder} from '@microsoft/signalr'

// const Content = styled('div')(({theme}) => ({
//     position: 'relative',
//     zIndex: 1
// }));

const StyledBackdrop = styled(Backdrop)(({theme}) => ({
    position: 'fixed',
    zIndex: 5000,
    backgroundColor: 'rgba(255, 255, 255, 0.9)'
}));

export default function ProgressBackdrop(props) {
    const {
        children
    } = props

    const [state, setState] = React.useState({
        title: '',
        show: false,
        percentComplete: null
    });
    const [connection, setConnection] = React.useState(null);

    React.useEffect(() => {
        const newConnection = new HubConnectionBuilder()
            .withUrl('/hubs/progress')
            .withAutomaticReconnect()
            .build();

        setConnection(newConnection);
    }, []);

    React.useEffect(() => {
        if (connection && connection.state !== "Connected") {
            connection.start()
                .then(result => {
                    connection.on('UpdateProgress', progress => {
                        const isComplete = get(progress, 'isComplete') || false
                        state.title = progress.title
                        state.show = !isComplete
                        state.percentComplete = progress.percentComplete
                        setState({...state})
                    });
                })
                .catch(e => console.log('Connection failed: ', e));
        }
    }, [connection, setState, state]);

    const {
        title,
        show,
        percentComplete
    } = state

    console.log(state)
    
    const handleCancel = async () => {
        const response = await fetch('cancel', {method: 'POST'});
        if (!response.ok) {
            console.error("Failed to cancel")
        }

        setState({
            ...state,
            title: '',
            show: false,
            percentComplete: null
        })
    }

    const renderProgress = (percentComplete) => {
        return <LinearProgress variant="determinate" color="primary" value={percentComplete || 0} sx={{mt: 1}}/>
    }

    const renderPercentage = (percentComplete) => {
        if (percentComplete == null) {
            return null
        }

        return (
            <Typography variant="caption" component="div" color="text.secondary">
                {`${percentComplete}%`}
            </Typography>
        )
    }

    return (
        <React.Fragment>
            {children}
            <StyledBackdrop open={show}>
                <Container maxWidth="sm">
                    <Card>
                        <CardContent>
                            <Box sx={{
                                mt: 1,
                                display: 'flex',
                                justifyContent: 'center'
                            }}>
                                <Typography variant="h6">
                                    {title || ''}
                                </Typography>
                            </Box>
                            {renderProgress(percentComplete)}
                            <Box sx={{
                                mt: 1,
                                display: 'flex',
                                justifyContent: 'center'
                            }}>
                                {renderPercentage(percentComplete)}
                                <Button
                                    variant="contained"
                                    startIcon={<FontAwesomeIcon icon="ban"/>}
                                    onClick={() => handleCancel()}
                                >
                                    Cancel
                                </Button>
                            </Box>
                        </CardContent>
                    </Card>
                </Container>
            </StyledBackdrop>
        </React.Fragment>
    )
}