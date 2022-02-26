import React from 'react'
import Title from "../components/Title";
import Grid from "@mui/material/Grid";
import Box from "@mui/material/Box";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import TextField from "../components/TextField";
import {get, isNil, set} from "lodash";
import BrowseOpenDialog from "../components/BrowseOpenDialog";
import Media from "../components/Media";
import Stack from "@mui/material/Stack";
import Radio from '@mui/material/Radio';
import RadioGroup from '@mui/material/RadioGroup';
import FormControlLabel from '@mui/material/FormControlLabel';
import FormControl from '@mui/material/FormControl';
import FormLabel from '@mui/material/FormLabel';
import RedirectButton from "../components/RedirectButton";
import Button from "../components/Button";
import MediaSelectField from "../components/MediaSelectField";

const initialState = {
    medias: null,
    mediaInfo: null,
    path: null,
    sourceType: 'image-file'
}

export default function Info() {
    const [state, setState] = React.useState({ ...initialState })
    const [session, updateSession] = React.useReducer((x) => x + 1, 0)
    
    const {
        mediaInfo,
        path,
        sourceType
    } = state

    const getInfoDisabled = isNil(path)

    const handleChange = ({name, value}) => {
        if (name === 'sourceType') {
            state.path = null
            state.mediaInfo = null
        }
        set(state, name, value)
        setState({...state})
    }

    const getMediaInfo = async (path) => {
        const response = await fetch('api/info', {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                path
            })
        });
        
        state.path = path
        
        if (!response.ok) {
            console.error('Failed to read')
            setState({
                ...state,
                mediaInfo: null
            })
            return
        }
        setState({
            ...state,
            mediaInfo: await response.json()
        })
    }
    
    const handleCancel = () => {
        setState({ ...initialState })
    }
    
    return (
        <React.Fragment>
            <Title
                text="Info"
                description="Display information about physical disk or image file."
            />
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item xs={12} lg={6}>
                    <FormControl>
                        <FormLabel id="source-type-label">Source</FormLabel>
                        <RadioGroup
                            row
                            aria-labelledby="source-type-label"
                            name="source-type"
                            value={sourceType || ''}
                            onChange={(event) => handleChange({
                                name: 'sourceType',
                                value: event.target.value
                            })}
                        >
                            <FormControlLabel value="image-file" control={<Radio />} label="Image file" />
                            <FormControlLabel value="physical-disk" control={<Radio />} label="Physical disk" />
                        </RadioGroup>
                    </FormControl>
                </Grid>
            </Grid>
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item xs={12} lg={6}>
                    {sourceType === 'image-file' && (
                        <TextField
                            id="image-path"
                            label={
                                <div style={{display: 'flex', alignItems: 'center', verticalAlign: 'bottom'}}>
                                    <FontAwesomeIcon icon="file" style={{marginRight: '5px'}} /> Image file
                                </div>
                            }
                            value={path || ''}
                            endAdornment={
                                <BrowseOpenDialog
                                    id="browse-image-path"
                                    title="Select image file"
                                    onChange={async (path) => await getMediaInfo(path)}
                                />
                            }
                            onChange={(event) => handleChange({
                                name: 'path',
                                value: get(event, 'target.value'
                                )
                            })}
                            onKeyDown={async (event) => {
                                if (event.key !== 'Enter') {
                                    return
                                }
                                await getMediaInfo(path)
                            }}
                        />
                    )}
                    {sourceType === 'physical-disk' && (
                        <MediaSelectField
                            label={
                                <div style={{display: 'flex', alignItems: 'center', verticalAlign: 'bottom'}}>
                                    <FontAwesomeIcon icon="hdd" style={{marginRight: '5px'}} /> Physical disk
                                </div>
                            }
                            id="media-path"
                            path={path || ''}
                            session={session}
                            onChange={async (media) => await getMediaInfo(media.path)}
                        />
                    )}
                    </Grid>
            </Grid>
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item xs={12} lg={6}>
                    <Box display="flex" justifyContent="flex-end">
                        <Stack direction="row" spacing={2} sx={{mt: 2}}>
                            <RedirectButton
                                path="/"
                                icon="ban"
                                onClick={async () => handleCancel()}
                            >
                                Cancel
                            </RedirectButton>
                            <Button
                                icon="sync-alt"
                                onClick={() => updateSession()}
                            >
                                Update
                            </Button>
                            <Button
                                disabled={getInfoDisabled}
                                icon="info"
                                onClick={async () => await getMediaInfo(path)}
                            >
                                Get info
                            </Button>
                        </Stack>
                    </Box>
                </Grid>
            </Grid>
            {mediaInfo && (
                <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                    <Grid item xs={12}>
                        <Media media={mediaInfo}/>
                    </Grid>
                </Grid>
            )}
        </React.Fragment>
    )
}