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
import RedirectButton from "../components/RedirectButton";
import Button from "../components/Button";

const initialState = {
    medias: null,
    mediaInfo: null,
    mediaPath: null,
    imagePath: null
}

export default function Info() {
    const [state, setState] = React.useState({ ...initialState })

    const {
        mediaInfo,
        mediaPath,
        imagePath
    } = state

    const getInfoDisabled = isNil(mediaPath) && isNil(imagePath)

    const handleChange = ({name, value}) => {
        set(state, name, value)
        setState({...state})
    }

    const getMediaInfo = async (path) => {
        const response = await fetch('info', {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                path
            })
        });
        if (!response.ok) {
            console.error('Failed to read')
        }
        setState({
            ...state,
            mediaInfo: await response.json()
        })
    }
    
    const handleCancel = () => {
        setState({ ...initialState })
    }
    
    const handleGetInfo = async () => {
        await getMediaInfo(isNil(mediaPath) ? imagePath : mediaPath)
    }

    console.log(mediaInfo)
    
    return (
        <React.Fragment>
            <Title
                text="Info"
                description="Display information about physical disk or image file."
            />
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item xs={12} sm={6}>
                    <TextField
                        id="image-path"
                        label={
                            <div style={{display: 'flex', alignItems: 'center', verticalAlign: 'bottom'}}>
                                <FontAwesomeIcon icon="file" style={{marginRight: '5px'}} /> Image file
                            </div>
                        }
                        value={imagePath || ''}
                        endAdornment={
                            <BrowseOpenDialog
                                id="browse-image-path"
                                title="Select image file"
                                fileFilters={[{
                                    name: 'Image file',
                                    extensions: ['img', 'hdf']
                                }, {
                                    name: 'Virtual hard disk',
                                    extensions: ['vhd']
                                }]}
                                onChange={(result) => handleChange({
                                    name: 'imagePath',
                                    value: result.path
                                })}
                            />
                        }
                        onChange={(event) => handleChange({
                            name: 'imagePath',
                            value: get(event, 'target.value'
                            )
                        })}
                    />
                </Grid>
            </Grid>
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item xs={12} sm={6} ali>
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
                                disabled={getInfoDisabled}
                                icon="info"
                                onClick={async () => await handleGetInfo()}
                            >
                                Get info
                            </Button>
                        </Stack>
                    </Box>
                </Grid>
            </Grid>
            {mediaInfo && (
                <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                    <Grid item xs={12} sm={6}>
                        <Media media={mediaInfo}/>
                    </Grid>
                </Grid>
            )}
        </React.Fragment>
    )
}