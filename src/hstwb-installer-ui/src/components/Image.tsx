import React from 'react';
import { Button } from '@material-ui/core';
const { dialog } = window.require('electron').remote;

class Image extends React.Component {
  openDialog = () => {
    const selectedPaths = dialog.showOpenDialog();
    console.log(selectedPaths);
  }

  render() {
    return (
      <React.Fragment>
        <h2>Image</h2>
        <Button onClick={() => this.openDialog()}>Open</Button>
      </React.Fragment>
    );
  }
}

export default Image;
