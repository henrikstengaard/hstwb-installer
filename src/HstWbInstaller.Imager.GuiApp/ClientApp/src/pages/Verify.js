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
import ConfirmDialog from "../components/ConfirmDialog";
import {Api} from "../utils/Api";

const initialState = {
    confirmOpen: false,
    sourceMedia: null,
    sourcePath: null,
    sourceType: 'ImageFile'
}

export default function Verify() {
    const [state, setState] = React.useState({ ...initialState })
    const [destinationPath, setDestinationPath] = React.useState(null)

    const api = new Api()
    
    const {
        confirmOpen,
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

    const handleVerify = async () => {
        const response = await fetch('api/verify', {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                title: `Verify ${(sourceType === 'ImageFile' ? 'image file' : 'disk')} '${isNil(sourceMedia) ? sourcePath : sourceMedia.model}' and image file '${destinationPath}'`,
                sourceType,
                sourcePath,
                destinationPath 
            })
        });
        if (!response.ok) {
            console.error('Failed to verify')
        }
    }

    const handleConfirm = async (confirmed) => {
        setState({
            ...state,
            confirmOpen: false
        })
        if (!confirmed) {
            return
        }
        await handleVerify()
    }

    const handleCancel = () => {
        setState({ ...initialState })
    }
    
    const handleUpdate = async () => {
        await api.list()
    }
    
    return (
        <Box>
            <ConfirmDialog
                id="confirm-verify"
                open={confirmOpen}
                title="Verify"
                description={`Do you want to verify '${isNil(sourceMedia) ? sourcePath : sourceMedia.model}' and '${destinationPath}'?`}
                onClose={async (confirmed) => await handleConfirm(confirmed)}
            />
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
                            <FormControlLabel value="ImageFile" control={<Radio />} label="Image file" />
                            <FormControlLabel value="PhysicalDisk" control={<Radio />} label="Physical disk" />
                        </RadioGroup>
                    </FormControl>
                </Grid>
            </Grid>
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item xs={12} lg={6}>
                    {sourceType === 'ImageFile' && (
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
                    {sourceType === 'PhysicalDisk' && (
                        <MediaSelectField
                            label={
                                <div style={{display: 'flex', alignItems: 'center', verticalAlign: 'bottom'}}>
                                    <FontAwesomeIcon icon="hdd" style={{marginRight: '5px'}} /> Source physical disk
                                </div>
                            }
                            id="source-media-path"
                            path={sourcePath || ''}
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
                                onChange={(path) => setDestinationPath(path)}
                            />
                        }
                        onChange={(event) => setDestinationPath(get(event, 'target.value'))}
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
                                onClick={async () => handleUpdate()}
                            >
                                Update
                            </Button>
                            <Button
                                disabled={verifyDisabled}
                                icon="check"
                                onClick={async () => handleChange({
                                    name: 'confirmOpen',
                                    value: true
                                })}
                            >
                                Start verify
                            </Button>
                        </Stack>
                    </Box>
                </Grid>
            </Grid>
        </Box>
    )        
}