import {get, isNil} from 'lodash'
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
import Stack from "@mui/material/Stack";
import {formatBytes, formatMilliseconds} from "../utils/Format";

const initialState = {
    title: '',
    show: false,
    percentComplete: null,
    bytesProcessed: null,
    bytesRemaining: null,
    bytesTotal: null,
    millisecondsElapsed: null,
    millisecondsRemaining: null,
    millisecondsTotal: null
}

const StyledBackdrop = styled(Backdrop)(({theme}) => ({
    position: 'fixed',
    zIndex: 5000,
    backgroundColor: 'rgba(0, 0, 0, 0.7)'
}));

export default function ProgressBackdrop(props) {
    const {
        children
    } = props

    const [state, setState] = React.useState({...initialState});
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
                        state.bytesProcessed = isComplete ? null : progress.bytesProcessed
                        state.bytesRemaining = isComplete ? null : progress.bytesRemaining
                        state.bytesTotal = isComplete ? null : progress.bytesTotal
                        state.millisecondsElapsed = isComplete ? null : progress.millisecondsElapsed
                        state.millisecondsRemaining = isComplete ? null : progress.millisecondsRemaining
                        state.millisecondsTotal = isComplete ? null : progress.millisecondsTotal
                        setState({...state})
                    });
                })
                .catch(e => console.log('Connection failed: ', e));
        }
    }, [connection, setState, state]);

    const {
        title,
        show,
        percentComplete,
        bytesProcessed,
        bytesRemaining,
        bytesTotal,
        millisecondsElapsed,
        millisecondsRemaining,
        millisecondsTotal
    } = state

    const handleCancel = async () => {
        const response = await fetch('cancel', {method: 'POST'});
        if (!response.ok) {
            console.error("Failed to cancel")
        }

        setState({...initialState})
    }

    const renderProgress = (percentComplete) => {
        return <LinearProgress variant="determinate" color="primary"
                               value={isNil(percentComplete) ? 1 : percentComplete} sx={{mt: 1}}/>
    }

    const renderText = (text) => {
        if (isNil(text)) {
            return null
        }

        return (
            <Typography variant="caption" align="center" component="div" color="text.secondary">
                {text}
            </Typography>
        )
    }

    const percentageText = isNil(percentComplete) ? null : `${parseFloat(percentComplete).toFixed(1)} %`
    const bytesText = !isNil(bytesProcessed) && !isNil(bytesTotal) && !isNil(bytesRemaining)
        ? `${formatBytes(bytesProcessed)} of ${formatBytes(bytesTotal)} processed, ${formatBytes(bytesRemaining)} remaining`
        : null
    const timeText = !isNil(millisecondsElapsed) && !isNil(millisecondsTotal) && !isNil(millisecondsRemaining)
        ? `${formatMilliseconds(millisecondsElapsed)} elapsed of ${formatMilliseconds(millisecondsTotal)}, ${formatMilliseconds(millisecondsRemaining)} remaining`
        : null

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
                                <Stack direction="column" spacing={1}>
                                    {renderText(percentageText)}
                                    {renderText(bytesText)}
                                    {renderText(timeText)}
                                </Stack>
                            </Box>
                            <Box sx={{
                                mt: 1,
                                display: 'flex',
                                justifyContent: 'center'
                            }}>
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