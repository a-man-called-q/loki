import { defineCollection, z } from "astro:content";
import { glob } from "astro/loaders";

const changelog = defineCollection({
  loader: glob({ pattern: "**/*.md", base: "./src/content/changelog" }),
  schema: z.object({
    title: z.string(),
    date: z.date(),
    version: z.string().optional(),
    description: z.string(),
  }),
});

export const collections = { changelog };
