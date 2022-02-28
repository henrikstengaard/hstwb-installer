import React from 'react'
import Title from "../components/Title";
import Box from "@mui/material/Box";
import {get, isNil, set} from "lodash";
import Grid from "@mui/material/Grid";
import MediaSelectField from "../components/MediaSelectField";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import TextField from "../components/TextField";
import Stack from "@mui/material/Stack";
import RedirectButton from "../components/RedirectButton";
import Button from "../components/Button";
import BrowseOpenDialog from "../components/BrowseOpenDialog";
import ConfirmDialog from "../components/ConfirmDialog";

const initialState = {
    confirmOpen: false,
    sourcePath: null,
    destinationMedia: null
}

export default function Write() {
    const [state, setState] = React.useState({...initialState})
    const [session, updateSession] = React.useReducer((x) => x + 1, 0)

    const {
        confirmOpen,
        sourcePath,
        destinationMedia
    } = state

    const handleChange = ({name, value}) => {
        set(state, name, value)
        setState({...state})
    }

    const handleCancel = () => {
        setState({...initialState})
    }

    const handleWrite = async () => {
        const response = await fetch('api/write', {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                title: `Write file '${sourcePath}' to disk '${get(destinationMedia, 'model') || ''}'`,
                sourcePath,
                destinationPath: destinationMedia.path,
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
        await handleWrite()
    }
    
    const writeDisabled = isNil(sourcePath) || isNil(destinationMedia)

    return (
        <Box>
            <ConfirmDialog
                id="confirm-write"
                open={confirmOpen}
                title="Write"
                description={`Do you want to write file '${sourcePath}' to disk '${get(destinationMedia, 'model') || ''}'?`}
                onClose={async (confirmed) => await handleConfirm(confirmed)}
            />
            <Title
                text="Write"
                description="Write image file to physical disk."
            />
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item xs={12} lg={6}>
                    <TextField
                        id="source-path"
                        label={
                            <div style={{display: 'flex', alignItems: 'center', verticalAlign: 'bottom'}}>
                                <FontAwesomeIcon icon="file" style={{marginRight: '5px'}} /> Source file
                            </div>
                        }
                        value={sourcePath || ''}
                        endAdornment={
                            <BrowseOpenDialog
                                id="browse-source-path"
                                title="Select source image file"
                                fileFilters={[{
                                    name: 'Image file',
                                    extensions: ['img', 'hdf']
                                }, {
                                    name: 'Virtual hard disk',
                                    extensions: ['vhd']
                                }]}
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
                </Grid>
            </Grid>
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item xs={12} lg={6}>
                    <MediaSelectField
                        label={
                            <div style={{display: 'flex', alignItems: 'center', verticalAlign: 'bottom'}}>
                                <FontAwesomeIcon icon="hdd" style={{marginRight: '5px'}} /> Destination disk
                            </div>
                        }
                        id="destination-media"
                        path={get(destinationMedia, 'path') || ''}
                        session={session}
                        onChange={(media) => handleChange({
                            name: 'destinationMedia',
                            value: media
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
                                disabled={writeDisabled}
                                icon="download"
                                onClick={async () => handleChange({
                                    name: 'confirmOpen',
                                    value: true
                                })}
                            >
                                Start write
                            </Button>
                        </Stack>
                    </Box>
                </Grid>
            </Grid>
        </Box>
    )
}