# Chapter 7 Product contract

This chapter retains the reviewed Chapter 6 OpenAPI 3.1.1 contract and its
Problem Details responses. The Product API still stores data in memory.
The separate PostgreSQL lab does not change HTTP behavior.

Open `northstar-product-api.yaml` here and compare it with `/v3/api-docs` from
the running application. Use the Maven Wrapper and client commands in the
project README. No private textbook validator is required.

Bearer-token expectations describe future policy, not implemented security.
Spring/Jackson can coerce some inputs, and the DTO rejects blank names more
strictly than the schema's minimum length. These examples do not establish
complete JSON Schema input enforcement.
