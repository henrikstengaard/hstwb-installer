import React from 'react'
import {useHistory} from 'react-router-dom'
import Box from '@mui/material/Box'
import Grid from '@mui/material/Grid'
import Card from '@mui/material/Card'
import CardActionArea from '@mui/material/CardActionArea'
import CardContent from '@mui/material/CardContent'
import Typography from '@mui/material/Typography'
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome'

export default function Main() {
    const history = useHistory()

    return (
        <Box sx={{ m: 1 }}>
            <Grid container spacing={1}>
                <Grid item xs={6}>
                    <Card>
                        <CardActionArea onClick={() => history.push('/read')}>
                            <CardContent>
                                <Grid container alignItems="center" spacing={2}>
                                    <Grid item>
                                        <Typography variant="h3">
                                            Read
                                        </Typography>
                                    </Grid>
                                    <Grid item>
                                        <FontAwesomeIcon icon="hdd" size="2x" />
                                    </Grid>
                                    <Grid item>
                                        <FontAwesomeIcon icon="long-arrow-alt-right" size="2x" />
                                    </Grid>
                                    <Grid item>
                                        <FontAwesomeIcon icon="file" size="2x" />
                                    </Grid>
                                </Grid>
                                <Typography>
                                    Read physical drive to image file.
                                </Typography>
                            </CardContent>
                        </CardActionArea>
                    </Card>
                </Grid>
                <Grid item xs={6}>
                    <Card>
                        <CardActionArea onClick={() => history.push('/write')}>
                            <CardContent>
                                <Grid container alignItems="center" spacing={2}>
                                    <Grid item>
                                        <Typography variant="h3">
                                            Write
                                        </Typography>
                                    </Grid>
                                    <Grid item>
                                        <FontAwesomeIcon icon="file" size="2x" />
                                    </Grid>
                                    <Grid item>
                                        <FontAwesomeIcon icon="long-arrow-alt-right" size="2x" />
                                    </Grid>
                                    <Grid item>
                                        <FontAwesomeIcon icon="hdd" size="2x" />
                                    </Grid>
                                </Grid>
                                
                                <Typography>
                                    Write image file to physical drive.
                                </Typography>
                            </CardContent>
                        </CardActionArea>
                    </Card>
                </Grid>
                <Grid item xs={6}>
                    <Card>
                        <CardActionArea onClick={() => history.push('/convert')}>
                            <CardContent>
                                <Grid container alignItems="center" spacing={2}>
                                    <Grid item>
                                        <Typography variant="h3">
                                            Convert
                                        </Typography>
                                    </Grid>
                                    <Grid item>
                                        <FontAwesomeIcon icon="file" size="2x" />
                                    </Grid>
                                    <Grid item>
                                        <FontAwesomeIcon icon="long-arrow-alt-right" size="2x" />
                                    </Grid>
                                    <Grid item>
                                        <FontAwesomeIcon icon="file" size="2x" />
                                    </Grid>
                                </Grid>
                                <Typography>
                                    Convert image file from one format to another.
                                </Typography>
                            </CardContent>
                        </CardActionArea>
                    </Card>
                </Grid>
                <Grid item xs={6}>
                    <Card>
                        <CardActionArea onClick={() => history.push('/convert')}>
                            <CardContent>
                                <Grid container alignItems="center" spacing={2}>
                                    <Grid item>
                                        <Typography variant="h3">
                                            Verify
                                        </Typography>
                                    </Grid>
                                    <Grid item>
                                        <FontAwesomeIcon icon="file" size="2x" />
                                    </Grid>
                                    <Grid item>
                                        <FontAwesomeIcon icon="exchange-alt" size="2x" />
                                    </Grid>
                                    <Grid item>
                                        <FontAwesomeIcon icon="hdd" size="2x" />
                                    </Grid>
                                </Grid>
                                <Typography>
                                    Verify image file and physical drive.
                                </Typography>
                            </CardContent>
                        </CardActionArea>
                    </Card>
                </Grid>
                <Grid item xs={6}>
                    <Card>
                        <CardActionArea onClick={() => history.push('/blank')}>
                            <CardContent>
                                <Grid container alignItems="center" spacing={2}>
                                    <Grid item>
                                        <Typography variant="h3">
                                            Blank
                                        </Typography>
                                    </Grid>
                                    <Grid item>
                                        <FontAwesomeIcon icon="file" size="2x" />
                                    </Grid>
                                </Grid>
                                <Typography>
                                    Create blank image file.
                                </Typography>
                            </CardContent>
                        </CardActionArea>
                    </Card>
                </Grid>
                <Grid item xs={6}>
                    <Card>
                        <CardActionArea onClick={() => history.push('/optimize')}>
                            <CardContent>
                                <Grid container alignItems="center" spacing={2}>
                                    <Grid item>
                                        <Typography variant="h3">
                                            Optimize
                                        </Typography>
                                    </Grid>
                                    <Grid item>
                                        <FontAwesomeIcon icon="magic" size="2x" />
                                    </Grid>
                                </Grid>
                                <Typography>
                                    Optimize image file.
                                </Typography>
                            </CardContent>
                        </CardActionArea>
                    </Card>
                </Grid>
            </Grid>
        </Box>
    )
}
