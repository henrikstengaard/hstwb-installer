import {get, isNil, set} from 'lodash'
import React from 'react'
import Box from '@mui/material/Box'
import Grid from '@mui/material/Grid'
import Stack from '@mui/material/Stack'
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome"
import Media from '../components/Media'
import Button from '../components/Button'
import BrowseSaveDialog from "../components/BrowseSaveDialog";
import Title from "../components/Title";
import TextField from '../components/TextField'
import RedirectButton from "../components/RedirectButton";
import MediaSelectField from "../components/MediaSelectField";

const initialState = {
    sourceMedia: null,
    destinationPath: null
}

export default function Read() {
    const [state, setState] = React.useState({...initialState})

    const {
        sourceMedia,
        destinationPath
    } = state

    const handleChange = ({name, value}) => {
        set(state, name, value)
        setState({...state})
    }

    const handleCancel = () => {
        setState({...initialState})
    }

    const handleRead = async () => {
        const response = await fetch('read', {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                title: `Reading disk '${sourceMedia.model}' to file '${destinationPath}'`,
                sourcePath: sourceMedia.path,
                destinationPath
            })
        });
        if (!response.ok) {
            console.error('Failed to read')
        }
    }

    const readDisabled = isNil(sourceMedia) || isNil(destinationPath)

    return (
        <Box>
            <Title
                text="Read"
                description="Read physical disk to image file."
            />
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item xs={12} sm={6}>
                    <MediaSelectField
                        label={<React.Fragment><FontAwesomeIcon icon="hdd"/> Source disk</React.Fragment>}
                        id="source-disk"
                        path={get(sourceMedia, 'path') || ''}
                        onChange={(media) => handleChange({
                            name: 'sourceMedia',
                            value: media
                        })}
                    />
                </Grid>
            </Grid>
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item xs={12} sm={6}>
                    <TextField
                        id="destination-file"
                        label={<React.Fragment><FontAwesomeIcon icon="file" /> Destination file</React.Fragment>}
                        value={destinationPath || ''}
                        endAdornment={
                            <BrowseSaveDialog
                                id="read-destination-path"
                                title="Select destination image"
                                fileFilters={[{
                                    name: 'Image file',
                                    extensions: ['img', 'hdf']
                                }, {
                                    name: 'Virtual hard disk',
                                    extensions: ['vhd']
                                }]}
                                onChange={(result) => handleChange({
                                    name: 'destinationPath',
                                    value: result.path
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
                <Grid item xs={12} sm={6}>
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
                            >
                                Update
                            </Button>
                            <Button
                                disabled={readDisabled}
                                icon="upload"
                                onClick={async () => await handleRead()}
                            >
                                Start read
                            </Button>
                        </Stack>
                    </Box>
                </Grid>
            </Grid>
            {sourceMedia && (
                <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                    <Grid item xs={12} sm={6}>
                        <Media media={sourceMedia}/>
                    </Grid>
                </Grid>
            )}
        </Box>
    )
}