import { Firestore } from '@google-cloud/firestore';

const db = new Firestore();
const collectionName = 'books';

export interface Book {
    id?: string;
    title: string;
    author: string;
    publishedDate: string;
    description: string;
    imageUrl?: string;
}

export const list = async (): Promise<Book[]> => {
    const snapshot = await db.collection(collectionName).orderBy('title').get();
    return snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() } as Book));
};

export const read = async (id: string): Promise<Book | null> => {
    const doc = await db.collection(collectionName).doc(id).get();
    if (!doc.exists) return null;
    return { id: doc.id, ...doc.data() } as Book;
};

export const create = async (data: Omit<Book, 'id'>): Promise<Book> => {
    const docRef = db.collection(collectionName).doc();
    await docRef.set(data);
    return { id: docRef.id, ...data };
};

export const update = async (id: string, data: Partial<Book>): Promise<Book> => {
    const docRef = db.collection(collectionName).doc(id);
    await docRef.set(data, { merge: true }); // merge: true osvežava samo prosleđena polja
    const updatedDoc = await docRef.get();
    return { id: updatedDoc.id, ...updatedDoc.data() } as Book;
};

export const deleteBook = async (id: string): Promise<void> => {
    await db.collection(collectionName).doc(id).delete();
};