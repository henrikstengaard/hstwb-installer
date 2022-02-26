import React from 'react'
import Box from "@mui/material/Box";
import Title from "../components/Title";
import {get, isNil, set} from "lodash";
import Grid from "@mui/material/Grid";
import TextField from "../components/TextField";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import BrowseOpenDialog from "../components/BrowseOpenDialog";
import Stack from "@mui/material/Stack";
import RedirectButton from "../components/RedirectButton";
import Button from "../components/Button";

const initialState = {
    path: null
}

export default function Optimize() {
    const [state, setState] = React.useState({ ...initialState })

    const {
        path
    } = state

    const handleOptimize = async () => {
        const response = await fetch('api/optimize', {
            method: 'POST',
            headers: {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                title: `Optimizing image file '${path}'`,
                path
            })
        });

        state.path = path
        setState({...state,})

        if (!response.ok) {
            console.error('Failed to optimize image')
        }
    }

    const handleChange = ({name, value}) => {
        set(state, name, value)
        setState({...state})
    }

    const handleCancel = () => {
        setState({ ...initialState })
    }

    const optimizeDisabled = isNil(path)

    return (
        <Box>
            <Title
                text="Optimize"
                description="Optimize image file."
            />
            <Grid container spacing="2" direction="row" alignItems="center" sx={{mt: 2}}>
                <Grid item xs={12} lg={6}>
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
                                onChange={(path) => handleChange({
                                    name: 'path',
                                    value: path
                                })}
                            />
                        }
                        onChange={(event) => handleChange({
                            name: 'path',
                            value: get(event, 'target.value'
                            )}
                        )}
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
                                disabled={optimizeDisabled}
                                icon="magic"
                                onClick={async () => await handleOptimize()}
                            >
                                Optimize image
                            </Button>
                        </Stack>
                    </Box>
                </Grid>
            </Grid>
        </Box>
    )
}