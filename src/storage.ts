import { Storage } from '@google-cloud/storage';
import path from 'path';
import 'multer'

const storage = new Storage();

export const uploadImage = async (file: Express.Multer.File, projectId: string): Promise<string | null> => {
    if (!file) return null;

    const bucketName = `${projectId}-covers`;
    const bucket = storage.bucket(bucketName);

    const ext = path.extname(file.originalname);
    const basename = path.basename(file.originalname, ext);
    const date = new Date().toISOString().replace(/[:.]/g, '-');
    const safeFilename = `${basename}-${date}${ext}`;

    const blob = bucket.file(safeFilename);

    // Uploadujemo fajl direktno iz memorije (buffer)
    await blob.save(file.buffer, {
        contentType: file.mimetype,
        resumable: false // Za male fajlove poput slika ovo je brže
    });

    // Vraćamo javni URL
    return `https://storage.googleapis.com/${bucketName}/${safeFilename}`;
};