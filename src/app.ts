import express from 'express';
import nunjucks from 'nunjucks';
import multer from 'multer';
import path from 'path';
import * as booksdb from './booksdb';
import * as storage from './storage';

const app = express();
const port = process.env.PORT || 8080;
const projectId = process.env.GOOGLE_CLOUD_PROJECT || 'sara-sandbox-interns';
const viewsPath = path.join(__dirname, '../views');

nunjucks.configure(viewsPath, {
    autoescape: true,
    express: app
});
app.set('views', viewsPath);
app.set('view engine', 'html');

// 2. Middleware za čitanje običnih tekstualnih polja iz HTML formi
app.use(express.urlencoded({ extended: true }));

// 3. Multer konfiguracija - hvata sliku iz forme i čuva je u RAM memoriji (buffer)
const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 8 * 1024 * 1024 } // Limit 8MB kao u Flasku
});


// Početna - izlistaj sve knjige
// 1. Početna strana (Dashboard)
app.get('/', async (req, res) => {
    const books = await booksdb.list();
    res.render('list.html', { books });
});

// 2. STRANICA ZA DODAVANJE (MORA BITI IZNAD /:id)
app.get('/books/add', (req, res) => {
    res.render('form.html', { action: 'Add', book: {} });
});

// 3. SNIMANJE NOVE KNJIGE (MORA BITI IZNAD /:id)
app.post('/books/add', upload.single('image'), async (req, res) => {
    const data = req.body;
    if (req.file) {
        const imageUrl = await storage.uploadImage(req.file, projectId);
        if (imageUrl) data.imageUrl = imageUrl;
    }
    const book = await booksdb.create(data);
    res.redirect(`/books/${book.id}`);
});

// 4. PREGLED POJEDINAČNE KNJIGE
app.get('/books/:id', async (req, res) => {
    const id = req.params.id as string;
    const book = await booksdb.read(id);
    if (!book) return res.status(404).send('Knjiga nije pronađena');
    res.render('view.html', { book });
});

// 5. IZMENA KNJIGE (GET)
app.get('/books/:id/edit', async (req, res) => {
    const id = req.params.id as string;
    const book = await booksdb.read(id);
    if (!book) return res.status(404).send('Knjiga nije pronađena');
    res.render('form.html', { action: 'Edit', book });
});

// 6. SNIMANJE IZMENA (POST)
app.post('/books/:id/edit', upload.single('image'), async (req, res) => {
    const id = req.params.id as string;
    const data = req.body;
    if (req.file) {
        const imageUrl = await storage.uploadImage(req.file, projectId);
        if (imageUrl) data.imageUrl = imageUrl;
    }
    await booksdb.update(id, data);
    res.redirect(`/books/${id}`);
});

// 7. BRISANJE
app.get('/books/:id/delete', async (req, res) => {
    const id = req.params.id as string;
    await booksdb.deleteBook(id);
    res.redirect('/');
});

// Pokretanje servera
app.listen(port, () => {
    console.log(`🚀 Server uspešno podignut na portu ${port}`);
    console.log(`🎯 Ciljani GCP Projekat za Storage: ${projectId}`);
});