import React from 'react'
import Box from "@mui/material/Box";
import Title from "../components/Title";
import Grid from "@mui/material/Grid";
import FormControl from "@mui/material/FormControl";
import FormLabel from "@mui/material/FormLabel";
import RadioGroup from "@mui/material/RadioGroup";
import FormControlLabel from "@mui/material/FormControlLabel";
import Radio from "@mui/material/Radio";
import TextField from "../components/TextField";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import BrowseOpenDialog from "../components/BrowseOpenDialog";
import {get, isNil, set} from "lodash";
import MediaSelectField from "../components/MediaSelectField";
import Stack from "@mui/material/Stack";
import RedirectButton from "../components/RedirectButton";
import Button from "../components/Button";

const initialState = {
    destinationPath: null,
    sourceMedia: null,
    sourcePath: null,
    sourceType: 'image-file'
}

export default function Verify() {
    const [state, setState] = React.useState({ ...initialState })
    const [session, updateSession] = React.useReducer((x) => x + 1, 0)

    const {
        destinationPath,
        sourceMedia,
        sourcePath,
        sourceType
    } = state

    const verifyDisabled = isNil(sourcePath) || isNil(destinationPath)

    const handleChange = ({name, value}) => {
        if (name === 'sourceType') {
            state.sourcePath = null
            state.sourceMedia = null
        }
        set(state, name, value)
        setState({...state})
    }
    
    const handleMediaChange = (media) => {
        state.sourceMedia = media
        state.sourcePath = media.path
        setState({...state})
    }

    const handleVerify = async (sourcePath, destinationPath) => {
        const response = await fetch('api/verify', {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                title: `Verify '${isNil(sourceMedia) ? sourcePath : sourceMedia.model}' and '${destinationPath}'`,
                sourcePath,
                destinationPath 
            })
        });

        state.sourcePath = sourcePath
        state.destinationPath = destinationPath

        if (!response.ok) {
            console.error('Failed to verify')
        }
        setState({
            ...state,
        })
    }

    const handleCancel = () => {
        setState({ ...initialState })
    }
    
    return (
        <Box>
            <Title
                text="Verify"
                description="Verify image files or physical disk and image file comparing them byte by byte."
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
                            id="source-image-path"
                            label={
                                <div style={{display: 'flex', alignItems: 'center', verticalAlign: 'bottom'}}>
                                    <FontAwesomeIcon icon="file" style={{marginRight: '5px'}} /> Source image file
                                </div>
                            }
                            value={sourcePath || ''}
                            endAdornment={
                                <BrowseOpenDialog
                                    id="browse-source-image-path"
                                    title="Select source image file"
                                    onChange={(path) => handleChange({
                                        name: 'sourcePath',
                                        value: path
                                    })}
                                />
                            }
                            onChange={(event) => handleChange({
                                name: 'sourcePath',
                                value: get(event, 'target.value'
                                )
                            })}
                        />
                    )}
                    {sourceType === 'physical-disk' && (
                        <MediaSelectField
                            label={
                                <div style={{display: 'flex', alignItems: 'center', verticalAlign: 'bottom'}}>
                                    <FontAwesomeIcon icon="hdd" style={{marginRight: '5px'}} /> Source physical disk
                                </div>
                            }
                            id="source-media-path"
                            path={sourcePath || ''}
                            session={session}
                            onChange={(media) => handleMediaChange(media)}
                        />
                    )}
                </Grid>
            </Grid>
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item xs={12} lg={6}>
                    <TextField
                        id="destination-path"
                        label={
                            <div style={{display: 'flex', alignItems: 'center', verticalAlign: 'bottom'}}>
                                <FontAwesomeIcon icon="file" style={{marginRight: '5px'}} /> Destination image file
                            </div>
                        }
                        value={destinationPath || ''}
                        endAdornment={
                            <BrowseOpenDialog
                                id="browse-destination-path"
                                title="Select destination image file"
                                onChange={(path) => handleChange({
                                    name: 'destinationPath',
                                    value: path
                                })}
                            />
                        }
                        onChange={(event) => handleChange({
                            name: 'destinationPath',
                            value: get(event, 'target.value'
                            )
                        })}
                    />
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
                                disabled={verifyDisabled}
                                icon="check"
                                onClick={async () => await handleVerify(sourcePath, destinationPath)}
                            >
                                Verify
                            </Button>
                        </Stack>
                    </Box>
                </Grid>
            </Grid>
        </Box>
    )        
}