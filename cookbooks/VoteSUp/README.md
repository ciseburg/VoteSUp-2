# VoteSUp-Configuration Managment

Cookbooks for setting up the VoteSUp application and any preqrequisites. 

## Attributes

<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['VoteSUp']['S3Bucket']</tt></td>
    <td>String</td>
    <td>The name of the S3 bucket that artifacts are stored in by the scripts and pipeline</td>
    <td><tt>true</tt></td>
  </tr>
  <tr>
    <td><tt>['VoteSUp']['ArtifactPath']</tt></td>
    <td>String</td>
    <td>The name of the artifact in the S3 bucket to deploy.</td>
    <td><tt>true</tt></td>
  </tr>
</table>

## Usage

### VoteSUp::default

Include `VoteSUp` in your node's `run_list`:

```json
{
  "run_list": [
    "recipe[VoteSUp::default]" 
    "recipe[VoteSUp::install_VoteSUp]""

  ]
}
```

`default` will install all prereqs.
`install_VoteSUp` will install the app.

## Testing

Test Kitchen should work straight away with only minor edits to your .kitchen.yml. You'll need to update the S3Bucket name and the Artifact Path.

Commands:

`kitchen create` to start your Vagrant VM.
`kitchen converge` to run your cookbooks.
`kitchen verify` to run your tests.
`kitchen destroy` to destroy your Vagrant VM.
`kitchen test` to do all those things.