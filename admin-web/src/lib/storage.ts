/**
 * Upload article images to ImgBB. Image URL is then stored in Firestore.
 * Get a free API key at https://api.imgbb.com/
 * Set NEXT_PUBLIC_IMGBB_API_KEY in .env.local
 */
export async function uploadArticleImage(
  _articleId: string,
  file: File
): Promise<string> {
  const apiKey = process.env.NEXT_PUBLIC_IMGBB_API_KEY;
  if (!apiKey) {
    throw new Error(
      'ImgBB API key missing. Set NEXT_PUBLIC_IMGBB_API_KEY in .env.local (get a free key at https://api.imgbb.com/)'
    );
  }

  const base64 = await fileToBase64(file);

  const res = await fetch(`https://api.imgbb.com/1/upload?key=${apiKey}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({ image: base64 }).toString(),
  });

  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Image upload failed (${res.status}): ${text}`);
  }

  const json = (await res.json()) as { success?: boolean; data?: { url?: string }; error?: { message?: string } };
  if (!json.success || !json.data?.url) {
    throw new Error(json.error?.message ?? 'Image upload failed: no URL returned');
  }

  return json.data.url;
}

function fileToBase64(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      const result = reader.result as string;
      // Strip data URL prefix (e.g. "data:image/jpeg;base64,")
      const base64 = result.includes(',') ? result.split(',')[1]! : result;
      resolve(base64);
    };
    reader.onerror = reject;
    reader.readAsDataURL(file);
  });
}
