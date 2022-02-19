import { get, set } from 'lodash'
import React from 'react'
import Box from '@mui/material/Box'
import Grid from '@mui/material/Grid'
import Stack from '@mui/material/Stack'
import InputLabel from '@mui/material/InputLabel'
import MenuItem from '@mui/material/MenuItem'
import FormControl from '@mui/material/FormControl'
import Select from '@mui/material/Select'
import IconButton from '@mui/material/IconButton'
import Typography from '@mui/material/Typography'
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome"
import Media from '../components/Media'
import {Button, TextField} from "@mui/material"
import BrowseSaveDialog from "../components/BrowseSaveDialog";

export default function Read() {
    const [state, setState] = React.useState({
        medias: null,
        sourcePath: null,
        destinationPath: null,
        loading: false
    });

    const handleGetMedias = React.useCallback(() => {
        async function getMedias() {
            const response = await fetch('list');
            const data = await response.json();
            setState({medias: data, loading: false});
        }

        getMedias()
    }, [setState])

    React.useEffect(() => {
        if (state.medias) {
            return
        }
        handleGetMedias()
    }, [state.medias, handleGetMedias])

    const {
        medias,
        sourcePath,
        destinationPath
    } = state

    const sourceMedia = (medias || []).find(media => media.path === sourcePath)

    const handleChangeSource = (event) => {
        setState({
            ...state,
            sourcePath: event.target.value
        })
    }

    const handleChange = ({name, value}) => {
        set(state, name, value)
        setState({...state})
    }

    const handleBrowseDestination = (path) => {
        setState({
            ...state,
            destinationPath: path
        })
    }

    const handleReadClick = async () => {
        const response = await fetch('read', {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                title: `Reading disk '${sourceMedia.model}' to file '${destinationPath}'`,
                sourcePath,
                destinationPath
            })
        });
        if (!response.ok) {
            console.error('Failed to read')
        }
    }

    return (
        <Box sx={{minWidth: 500}}>
            <Typography variant="h2">
                Read
            </Typography>
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item sx={{minWidth: 50}}>
                    <IconButton aria-label="source icon" disableRipple>
                        <FontAwesomeIcon icon="hdd"/>
                    </IconButton>
                </Grid>
                <Grid item sx={{minWidth: 600}}>
                    <FormControl variant="outlined" fullWidth>
                        <InputLabel id="source-label">Source disk</InputLabel>
                        <Select
                            labelId="source-label"
                            label="Source disk"
                            id="source"
                            value={sourcePath || ''}
                            onChange={handleChangeSource}
                        >
                            {(medias || []).map((media, index) => (
                                <MenuItem key={index} value={media.path}>{media.model}</MenuItem>))}
                        </Select>
                    </FormControl>
                </Grid>
                <Grid item>
                    <IconButton aria-label="refresh" disableRipple>
                        <FontAwesomeIcon icon="sync-alt"/>
                    </IconButton>
                </Grid>
            </Grid>
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item sx={{minWidth: 50}}/>
                <Grid item sx={{minWidth: 600}}>
                    {sourceMedia && (
                        <Media media={sourceMedia}/>
                    )}
                </Grid>
            </Grid>
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item sx={{minWidth: 50}}>
                    <IconButton aria-label="destination icon" disableRipple>
                        <FontAwesomeIcon icon="file"/>
                    </IconButton>
                </Grid>
                <Grid item sx={{minWidth: 600}}>
                    <TextField
                        fullWidth
                        id="destination-file"
                        label="Destination file"
                        value={destinationPath || ''}
                        onChange={(event) => handleChange({name: 'destinationPath', value: get(event, 'target.value') })}
                    />
                </Grid>
                <Grid item>
                    <BrowseSaveDialog id="read-destination-path"
                                      onChange={(result) => handleBrowseDestination(result.path)}/>
                </Grid>
            </Grid>
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item sx={{minWidth: 50}}/>
                <Grid item sx={{minWidth: 600}}>
                    <Stack direction="row" spacing={2} sx={{mt: 2}}>
                        <Button variant="contained" startIcon={<FontAwesomeIcon icon="upload"/>}
                                onClick={async () => await handleReadClick()}>
                            Read
                        </Button>
                        <Button variant="contained" startIcon={<FontAwesomeIcon icon="arrow-left"/>}>
                            Back
                        </Button>
                    </Stack>
                </Grid>
            </Grid>
        </Box>
    )
}