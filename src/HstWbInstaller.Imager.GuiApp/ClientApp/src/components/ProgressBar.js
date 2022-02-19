import React from 'react'
import Box from '@mui/material/Box'
import LinearProgress from '@mui/material/LinearProgress'
import {HubConnectionBuilder} from "@microsoft/signalr"

export default function ProgressBar() {
    const [ connection, setConnection ] = React.useState(null);
    const [ progress, setProgress ] = React.useState(null);

    React.useEffect(() => {
        const newConnection = new HubConnectionBuilder()
            .withUrl('/hubs/progress')
            .withAutomaticReconnect()
            .build();

        setConnection(newConnection);
    }, []);

    React.useEffect(() => {
        if (connection) {
            connection.start()
                .then(result => {
                    console.log('Connected!');

                    connection.on('UpdateProgress', progress => {
                        console.log(progress)
                        setProgress(progress);
                    });
                })
                .catch(e => console.log('Connection failed: ', e));
        }
    }, [connection]);
    
    const renderProgress = (progress) => {
        if (progress == null)
        {
            return <LinearProgress />
        }
        
        return <LinearProgress variant="determinate" value={progress.percentComplete} />
    }
    
    return(
        <Box sx={{ width: '100%' }}>
            {renderProgress(progress)}
        </Box>        
    )
}