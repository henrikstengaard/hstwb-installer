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
import {Button, TextField} from "@mui/material";

export default function Read() {
    const [state, setState] = React.useState({
        medias: null,
        source: null,
        loading: false
    });
    
    async function getMedias() {
        const response = await fetch('list');
        const data = await response.json();
        setState({ medias: data, loading: false });
    }

    React.useEffect(() => {
        if (state.medias) {
            return
        }
        getMedias()
    }, [state.medias, getMedias])
    
    const handleChangeSource = (event) =>{
        setState({ ...state, source: event.target.value})
    }
    
    const {
        medias,
        source
    } = state
    
    var sourceMedia = (medias || []).find(media => media.path === source)
    
    return (
        <Box sx={{minWidth: 500}}>
            <Typography variant="h2">
                Read
            </Typography>
            <Grid container spacing="2" direction="row" alignItems="center" sx={{ mt: 2 }}>
                <Grid item sx={{minWidth: 50}}>
                    <IconButton aria-label="source icon" disableRipple>
                        <FontAwesomeIcon icon="hdd" />
                    </IconButton>
                </Grid>
                <Grid item sx={{minWidth: 600}}>
                    <FormControl variant="outlined" fullWidth>
                        <InputLabel id="source-label">Source disk</InputLabel>
                        <Select
                            labelId="source-label"
                            label="Source disk"
                            id="source"
                            value={source || ''}
                            onChange={handleChangeSource}
                        >
                            {(medias || []).map((media, index)=> (<MenuItem key={index} value={media.path}>{media.model}</MenuItem>))}
                        </Select>
                    </FormControl>
                </Grid>
                <Grid item>
                    <IconButton aria-label="refresh" disableRipple>
                        <FontAwesomeIcon icon="sync-alt" />
                    </IconButton>
                </Grid>
            </Grid>
            <Grid container spacing="2" direction="row" alignItems="center" sx={{ mt: 2 }}>
                <Grid item sx={{minWidth: 50}}/>
                <Grid item sx={{minWidth: 600}}>
                    {sourceMedia && (
                        <Media media={sourceMedia} />
                    )}
                </Grid>
            </Grid>
            <Grid container spacing="2" direction="row" alignItems="center" sx={{ mt: 2 }}>
                <Grid item sx={{minWidth: 50}}>
                    <IconButton aria-label="destination icon" disableRipple>
                        <FontAwesomeIcon icon="file" />
                    </IconButton>
                </Grid>
                <Grid item sx={{minWidth: 600}}>
                    <TextField
                        fullWidth
                        id="destination-file"
                        label="Destination file"
                        defaultValue="c:\\temp\\4gb.img"
                    />
                </Grid>
                <Grid item>
                    <IconButton aria-label="browse" disableRipple>
                        <FontAwesomeIcon icon="ellipsis-h" />
                    </IconButton>
                </Grid>
            </Grid>
            <Grid container spacing="2" direction="row" alignItems="center" sx={{ mt: 2 }}>
                <Grid item sx={{minWidth: 50}}/>
                <Grid item sx={{minWidth: 600}}>
                    <Stack direction="row" spacing={2} sx={{ mt: 2 }}>
                        <Button variant="contained" startIcon={<FontAwesomeIcon icon="upload" />}>
                            Read
                        </Button>
                        <Button variant="contained" startIcon={<FontAwesomeIcon icon="ban" />}>
                            Cancel
                        </Button>
                    </Stack>
                </Grid>
            </Grid>
        </Box>
    )
}