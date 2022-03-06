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
import ConfirmDialog from "../components/ConfirmDialog";
import {Api} from "../utils/Api";

const initialState = {
    confirmOpen: false,
    sourceMedia: null,
    destinationPath: null
}

export default function Read() {
    const [state, setState] = React.useState({...initialState})
    // const [session, updateSession] = React.useReducer((x) => x + 1, 0)

    const api = new Api()
    
    const {
        confirmOpen,
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
        const response = await fetch('api/read', {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                title: `Reading disk '${get(sourceMedia, 'model') || ''}' to file '${destinationPath}'`,
                sourcePath: sourceMedia.path,
                destinationPath
            })
        });
        if (!response.ok) {
            console.error('Failed to read')
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
        await handleRead()
    }

    const handleUpdate = async () => {
        await api.list()
    }
    
    const readDisabled = isNil(sourceMedia) || isNil(destinationPath)

    return (
        <Box>
            <ConfirmDialog
                id="confirm-read"
                open={confirmOpen}
                title="Read"
                description={`Do you want to read disk '${get(sourceMedia, 'model') || ''}' to file '${destinationPath}'?`}
                onClose={async (confirmed) => await handleConfirm(confirmed)}
            />
            <Title
                text="Read"
                description="Read physical disk to image file."
            />
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item xs={12} lg={6}>
                    <MediaSelectField
                        label={
                            <div style={{display: 'flex', alignItems: 'center', verticalAlign: 'bottom'}}>
                                <FontAwesomeIcon icon="hdd" style={{marginRight: '5px'}} /> Source disk
                            </div>
                        }
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
                <Grid item xs={12} lg={6}>
                    <TextField
                        id="destination-file"
                        label={
                            <div style={{display: 'flex', alignItems: 'center', verticalAlign: 'bottom'}}>
                                <FontAwesomeIcon icon="file" style={{marginRight: '5px'}} /> Destination file
                            </div>
                        }
                        value={destinationPath || ''}
                        endAdornment={
                            <BrowseSaveDialog
                                id="read-destination-path"
                                title="Select destination image"
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
                                onClick={async () => handleUpdate()}
                            >
                                Update
                            </Button>
                            <Button
                                disabled={readDisabled}
                                icon="upload"
                                onClick={async () => handleChange({
                                    name: 'confirmOpen',
                                    value: true
                                })}
                            >
                                Start read
                            </Button>
                        </Stack>
                    </Box>
                </Grid>
            </Grid>
            {sourceMedia && (
                <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                    <Grid item xs={12}>
                        <Media media={sourceMedia}/>
                    </Grid>
                </Grid>
            )}
        </Box>
    )
}