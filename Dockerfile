# 1. Koristimo laganu verziju Node.js-a
FROM node:18-alpine

# 2. Pravimo radni folder unutar kontejnera
WORKDIR /usr/src/app

# 3. Prvo kopiramo package.json (zbog Docker keširanja)
COPY package*.json ./

# 4. Instaliramo sve pakete (uključujući ts-node, express, itd.)
RUN npm install

# 5. Kopiramo ostatak našeg koda (src, views, itd.)
COPY . .

# 6. Kažemo Cloud Run-u na kom portu slušamo (Cloud Run default je 8080)
EXPOSE 8080

# 7. Komanda za pokretanje aplikacije! 
# (Pošto nismo prevodili TS u JS unapred, koristićemo ts-node)
CMD ["npx", "ts-node", "src/app.ts"]