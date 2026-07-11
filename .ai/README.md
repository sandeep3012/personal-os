# AI Context Pack

Load in this order before generating code:

1. `.ai/MASTER_CONTEXT.md` — repository version, status, dependency chain
2. `.ai/Package_Dependency_Matrix.md` — allowed and forbidden dependencies
3. `.ai/Repository_Tree_v1.0.md` — canonical folder structure
4. Relevant architecture documents from `docs/architecture/` (DOC-001–DOC-030)
5. Relevant ADRs from `docs/adr/` (ADR-001 onwards)
6. Package README files
7. Existing implementation

See `.ai/governance/AI_Workflow.md` for the full workflow.
See `.ai/folder_structure.md` for the docs directory layout.
