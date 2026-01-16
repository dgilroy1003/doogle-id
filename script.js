const resourceName = 'doogle-id';

function $(id) { return document.getElementById(id); }

let uploadConfig = { enabled: false, url: '', apiKey: '' };

window.addEventListener('message', (event) => {
  const d = event.data;
  if (!d || !d.action) return;
  if (d.action === 'open') {
    document.getElementById('app').classList.remove('hidden');
    document.getElementById('viewer').classList.add('hidden');
  }
  if (d.action === 'view') {
    document.getElementById('viewer').classList.remove('hidden');
    document.getElementById('app').classList.add('hidden');
    $('viewImage').src = d.image;
  }
});

function drawCanvas(photoUrl, name, dob, height, haircolor, weight, pob, ppob) {
  const canvas = $('canvas');
  const ctx = canvas.getContext('2d');
  const bg = new Image();
  bg.src = 'assets/bg.svg';
  bg.onload = () => {
    ctx.clearRect(0,0,canvas.width,canvas.height);
    ctx.drawImage(bg, 0, 0, canvas.width, canvas.height);
    const photo = new Image();
    photo.crossOrigin = 'Anonymous';
    photo.onload = () => {
      // Photo box from config: x=520,y=120,w=220,h=260
      ctx.drawImage(photo, 520, 120, 220, 260);
      // Text
      ctx.fillStyle = '#000';
      ctx.font = '28px sans-serif';
      ctx.fillText(name || 'Unknown', 40, 140);
      ctx.font = '20px sans-serif';
      ctx.fillText('DOB: ' + (dob || '-'), 40, 180);
      ctx.fillText('Height: ' + (height || '-'), 40, 210);
      ctx.fillText('Weight: ' + (weight || '-'), 40, 240);
      ctx.fillText('Hair: ' + (haircolor || '-'), 40, 270);
      ctx.fillText('Birthplace: ' + (pob || '-'), 40, 300);
      ctx.fillText("Parent's Birthplace: " + (ppob || '-'), 40, 330);
    };
    photo.onerror = () => {
      ctx.fillStyle = '#000';
      ctx.font = '20px sans-serif';
      ctx.fillText('Photo load failed', 520, 260);
    };
    if (photoUrl && photoUrl.length > 0) photo.src = photoUrl;
  };
}

async function uploadImage(dataUrl) {
  if (!uploadConfig.enabled || !uploadConfig.url) return null;
  try {
    // Convert dataURL to blob
    const res = await fetch(dataUrl);
    const blob = await res.blob();

    const fd = new FormData();
    fd.append('image', blob, 'id.png');

    const headers = {};
    if (uploadConfig.apiKey && uploadConfig.apiKey.length > 0) {
      headers['Authorization'] = 'Bearer ' + uploadConfig.apiKey;
    }

    const resp = await fetch(uploadConfig.url, { method: 'POST', body: fd, headers });
    if (!resp.ok) return null;
    // Try parse JSON, else fallback to plain text URL (e.g., transfer.sh)
    let bodyText = await resp.text();
    try {
      const body = JSON.parse(bodyText);
      // Common response shapes: { url }, { data: { url } }, { data: { link } }, { link }
      return body.url || (body.data && (body.data.url || body.data.link)) || body.link || null;
    } catch (e) {
      // Not JSON — treat as plain text URL
      const trimmed = bodyText.trim();
      if (trimmed.startsWith('http')) return trimmed;
      return null;
    }
  } catch (e) {
    console.error('Upload failed', e);
    return null;
  }
}

function postToLua(endpoint, payload) {
  fetch(`https://${resourceName}/${endpoint}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(payload)
  }).then(r => r.json()).catch(e => console.error(e));
}

window.onload = async () => {
  // Load upload config from local JSON so server-side config isn't required
  try {
    const r = await fetch('upload-config.json');
    uploadConfig = await r.json();
  } catch (e) {
    uploadConfig = { enabled: false, url: '', apiKey: '' };
  }

  $('previewBtn').addEventListener('click', () => {
    const p = $('photo').value.trim();
    drawCanvas(p, $('name').value, $('dob').value, $('height').value, $('haircolor').value, $('weight').value, $('pob').value, $('ppob').value);
  });

  $('createBtn').addEventListener('click', async () => {
    const canvas = $('canvas');
    const imageData = canvas.toDataURL('image/png');

    let finalImage = imageData;
    if (uploadConfig.enabled && uploadConfig.url) {
      const uploaded = await uploadImage(imageData);
      if (uploaded) finalImage = uploaded; // use remote URL if upload successful
    }

    const payload = {
      name: $('name').value,
      dob: $('dob').value,
      height: $('height').value,
      haircolor: $('haircolor').value,
      weight: $('weight').value,
      placeOfBirth: $('pob').value,
      parentsPlaceOfBirth: $('ppob').value,
      image: finalImage,
      issued: new Date().toISOString().slice(0,10),
      idnumber: Math.floor(Math.random()*900000+100000).toString()
    };
    postToLua('create', payload);
    // close UI
    $('app').classList.add('hidden');
  });

  $('closeBtn').addEventListener('click', () => {
    postToLua('close', {});
    $('app').classList.add('hidden');
  });

  $('vclose').addEventListener('click', () => {
    $('viewer').classList.add('hidden');
  });
};
