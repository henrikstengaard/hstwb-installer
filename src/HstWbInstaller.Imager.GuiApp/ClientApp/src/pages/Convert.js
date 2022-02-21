import React from 'react'
import {get, isNil, set} from "lodash";
import Box from "@mui/material/Box";
import Title from "../components/Title";
import Grid from "@mui/material/Grid";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import TextField from "../components/TextField";
import BrowseSaveDialog from "../components/BrowseSaveDialog";
import Stack from "@mui/material/Stack";
import RedirectButton from "../components/RedirectButton";
import Button from "../components/Button";
import Media from "../components/Media";
import BrowseOpenDialog from "../components/BrowseOpenDialog";

const initialState = {
    sourcePath: null,
    destinationPath: null
}

export default function Convert() {
    const [state, setState] = React.useState({...initialState})

    const {
        sourcePath,
        destinationPath
    } = state

    const handleChange = ({name, value}) => {
        set(state, name, value)
        setState({...state})
    }

    const handleCancel = () => {
        setState({...initialState})
    }

    const handleConvert = async () => {
        const response = await fetch('convert', {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                title: `Reading disk '${sourcePath}' to file '${destinationPath}'`,
                sourcePath,
                destinationPath
            })
        });
        if (!response.ok) {
            console.error('Failed to convert')
        }
    }

    const convertDisabled = isNil(sourcePath) || isNil(destinationPath)

    return (
        <Box>
            <Title
                text="Convert"
                description="Convert image file from one format to another."
            />
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item xs={12} sm={6}>
                    <TextField
                        id="source-path"
                        label={<React.Fragment><FontAwesomeIcon icon="file" /> Source image file</React.Fragment>}
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
                                onChange={(result) => handleChange({
                                    name: 'sourcePath',
                                    value: result.path
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
                <Grid item xs={12} sm={6}>
                    <TextField
                        id="destination-path"
                        label={<React.Fragment><FontAwesomeIcon icon="file" /> Destination image file</React.Fragment>}
                        value={destinationPath || ''}
                        endAdornment={
                            <BrowseSaveDialog
                                id="browse-destination-path"
                                title="Select destination image file"
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
                                disabled={convertDisabled}
                                icon="exchange-alt"
                                onClick={async () => await handleConvert()}
                            >
                                Start convert
                            </Button>
                        </Stack>
                    </Box>
                </Grid>
            </Grid>
        </Box>
    )
}