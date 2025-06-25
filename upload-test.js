const fs = require('fs');
const path = require('path');
const { google } = require('googleapis');

const SCOPES = ['https://www.googleapis.com/auth/drive.file'];
const TOKEN_PATH = 'token.json';
const CREDENTIALS_PATH = 'credentials.json';

// const filePath = process.argv[2];
const filePath = ".gitignore"
if (!filePath || !fs.existsSync(filePath)) {
  console.error('❌ Invalid file path provided.');
  process.exit(1);
}

// Load credentials and start upload
fs.readFile(CREDENTIALS_PATH, (err, content) => {
  if (err) {
    console.error('❌ Error loading credentials.json:', err);
    process.exit(1);
  }
  authorize(JSON.parse(content), uploadFile);
});

function authorize(credentials, callback) {
  const { client_secret, client_id, redirect_uris } = credentials.installed || credentials.web;
  const oAuth2Client = new google.auth.OAuth2(client_id, client_secret, redirect_uris[0]);

  if (fs.existsSync(TOKEN_PATH)) {
    oAuth2Client.setCredentials(JSON.parse(fs.readFileSync(TOKEN_PATH)));
    callback(oAuth2Client);
  } else {
    console.error('❌ token.json not found. Please authorize the app first.');
    process.exit(1);
  }
}

async function uploadFile(auth) {
  const drive = google.drive({ version: 'v3', auth });

  const fileMetadata = {
    name: path.basename(filePath),
  };
  const media = {
    mimeType: 'application/zip',
    body: fs.createReadStream(filePath),
  };

  try {
    const res = await drive.files.create({
      resource: fileMetadata,
      media,
      fields: 'id',
    });

    const fileId = res.data.id;

    await drive.permissions.create({
      fileId,
      requestBody: {
        role: 'reader',
        type: 'anyone',
      },
    });

    const link = `https://drive.google.com/uc?id=${fileId}&export=download`;
    console.log(link); // <<-- Output only the link

  } catch (err) {
    console.error('❌ Upload failed:', err.message);
    process.exit(1);
  }
}
