import { Button } from './button';
import { Select } from './select';

interface PaginationControlsProps {
  page: number;
  pageCount: number;
  pageSize: number;
  onPageChange: (page: number) => void;
  onPageSizeChange?: (size: number) => void;
}

export function PaginationControls({
  page,
  pageCount,
  pageSize,
  onPageChange,
  onPageSizeChange,
}: PaginationControlsProps) {
  return (
    <div className="flex items-center justify-between">
      <div className="flex items-center gap-3">
        <p className="text-sm text-gray-500">
          Page {page} of {pageCount}
        </p>
        {onPageSizeChange && (
          <Select
            value={pageSize.toString()}
            onChange={(e) => onPageSizeChange(Number(e.target.value))}
            className="h-8 w-20"
          >
            <option value="10">10</option>
            <option value="20">20</option>
            <option value="50">50</option>
            <option value="100">100</option>
          </Select>
        )}
      </div>

      <div className="flex items-center gap-2">
        <Button
          variant="outline"
          size="sm"
          onClick={() => onPageChange(page - 1)}
          disabled={page <= 1}
        >
          Previous
        </Button>
        <Button
          variant="outline"
          size="sm"
          onClick={() => onPageChange(page + 1)}
          disabled={page >= pageCount}
        >
          Next
        </Button>
      </div>
    </div>
  );
}
